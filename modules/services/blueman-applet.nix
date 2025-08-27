{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.blueman-applet;
in
{
  options = {
    services.blueman-applet = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether to enable the Blueman applet.

          Note that for the applet to work, the `blueman` service should
          be enabled system-wide. You can enable it in the system
          configuration using
          ```nix
          services.blueman.enable = true;
          ```
        '';
      };

      package = lib.mkPackageOption pkgs "blueman" { };

      systemdTargets = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ "graphical-session.target" ];
        example = [ "sway-session.target" ];
        description = ''
          The systemd targets that will automatically start the blueman applet service.

          When setting this value to `["sway-session.target"]`,
          make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
          otherwise the service may never be started.
        '';
      };
    };
  };

  config = lib.mkIf config.services.blueman-applet.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.blueman-applet" pkgs lib.platforms.linux)
    ];

    systemd.user.services.blueman-applet = {
      Unit = {
        Description = "Blueman applet";
        Requires = [ "tray.target" ];
        After = cfg.systemdTargets ++ [ "tray.target" ];
        PartOf = cfg.systemdTargets;
      };

      Install = {
        WantedBy = cfg.systemdTargets;
      };

      Service = {
        ExecStart = "${lib.getExe' cfg.package "blueman-applet"}";
      };
    };
  };
}
