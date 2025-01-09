{ lib, ... }:

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

          When setting this value to `"sway-session.target"`,
          make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
          otherwise the service may never be started.
        '';
      };
    };
  };
}
