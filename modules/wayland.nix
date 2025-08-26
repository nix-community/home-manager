{ config, lib, ... }:

{
  meta.maintainers = [ lib.maintainers.thiagokokada ];

  options = {
    wayland = {
      systemd.target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the graphical Wayland services.
          This option is a generalization of individual `systemd.target` or `systemdTarget`,
          and affect all Wayland services by default.
        '';
      };
    };
  };

  config = lib.mkIf (!config.xsession.enable) {
    systemd.user.targets.tray = config.xsession.trayTarget;
  };
}
