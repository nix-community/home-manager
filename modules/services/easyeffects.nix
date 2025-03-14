{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.easyeffects;

  presetOpts = optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

in {
  meta.maintainers = [ maintainers.fufexan ];

  options.services.easyeffects = {
    enable = mkEnableOption ''
      Easyeffects daemon.
      Note, it is necessary to add
      ```nix
      programs.dconf.enable = true;
      ```
      to your system configuration for the daemon to work correctly'';

    package = mkOption {
      type = types.package;
      default = pkgs.easyeffects;
      defaultText = literalExpression "pkgs.easyeffects";
      description = "The `easyeffects` package to use.";
    };

    preset = mkOption {
      type = types.str;
      default = "";
      description = ''
        Which preset to use when starting easyeffects.
        Will likely need to launch easyeffects to initially create preset.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.easyeffects" pkgs platforms.linux)
    ];

    # running easyeffects will just attach itself to gapplication service
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = with pkgs; [ cfg.package at-spi2-core ];

    systemd.user.services.easyeffects = {
      Unit = {
        Description = "Easyeffects daemon";
        Requires = [ "dbus.service" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" "pipewire.service" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart =
          "${cfg.package}/bin/easyeffects --gapplication-service ${presetOpts}";
        ExecStop = "${cfg.package}/bin/easyeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
