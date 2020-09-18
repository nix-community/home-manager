{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.pulseeffects;

  presetOpts = optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

in {
  meta.maintainers = [ maintainers.jonringer ];

  options.services.pulseeffects = {
    enable = mkEnableOption "Pulseeffects daemon";

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
    # running pulseeffects will just attach itself to gapplication service
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = [ pkgs.pulseeffects pkgs.at-spi2-core ];

    # Will need to add `services.dbus.packages = with pkgs; [ gnome3.dconf ];`
    # to /etc/nixos/configuration.nix for daemon to work correctly

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
          "${pkgs.pulseeffects}/bin/pulseeffects --gapplication-service ${presetOpts}";
        ExecStop = "${pkgs.pulseeffects}/bin/pulseeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
