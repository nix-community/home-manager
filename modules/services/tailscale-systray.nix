{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.tailscale-systray;
in
{
  meta.maintainers = [ lib.maintainers.yethal ];

  options.services.tailscale-systray = {
    enable = lib.mkEnableOption "Official Tailscale systray application for Linux";

    package = lib.mkPackageOption pkgs "tailscale" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.tailscale-systray" pkgs lib.platforms.linux)
    ];

    systemd.user.services.tailscale-systray = {
      Unit = {
        Description = "Official Tailscale systray application for Linux";
        Requires = [ "tray.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${lib.getExe cfg.package} systray";
    };
  };
}
