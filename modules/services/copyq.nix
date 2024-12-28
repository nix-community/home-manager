{ config, lib, pkgs, ... }:

let

  cfg = config.services.copyq;

in {
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options.services.copyq = {
    enable =
      lib.mkEnableOption "CopyQ, a clipboard manager with advanced features";

    package = lib.mkPackageOption pkgs "copyq" { };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the CopyQ service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    forceXWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Force the CopyQ to use the X backend on wayland";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.copyq" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.copyq = {
      Unit = {
        Description = "CopyQ clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/copyq";
        Restart = "on-failure";
        Environment = lib.optional cfg.forceXWayland "QT_QPA_PLATFORM=xcb";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
