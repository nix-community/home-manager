{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.pulseeffects;

  presetOpts = optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

in {
  meta.maintainers = [ hm.maintainers.jonringer ];

  options.services.pulseeffects = {
    enable = mkEnableOption ''
      Pulseeffects daemon
      Note, it is necessary to add
      ```nix
      programs.dconf.enable = true;
      ```
      to your system configuration for the daemon to work correctly'';

    package = mkOption {
      type = types.package;
      default = pkgs.pulseeffects-legacy;
      defaultText = literalExpression "pkgs.pulseeffects-legacy";
      description = "Pulseeffects package to use.";
    };

    preset = mkOption {
      type = types.str;
      default = "";
      description = ''
        Which preset to use when starting pulseeffects.
        Will likely need to launch pulseeffects to initially create preset.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pulseeffects" pkgs
        lib.platforms.linux)
    ];

    # running pulseeffects will just attach itself to gapplication service
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = [ cfg.package pkgs.at-spi2-core ];

    systemd.user.services.pulseeffects = {
      Unit = {
        Description = "Pulseeffects daemon";
        Requires = [ "dbus.service" ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" "pulseaudio.service" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart =
          "${cfg.package}/bin/pulseeffects --gapplication-service ${presetOpts}";
        ExecStop = "${cfg.package}/bin/pulseeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
