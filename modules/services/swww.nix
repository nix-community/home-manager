{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.swww;
in
{
  meta.maintainers = with lib.hm.maintainers; [ hey2022 ];

  options.services.swww = {
    enable = lib.mkEnableOption "swww, a Solution to your Wayland Wallpaper Woes";
    package = lib.mkPackageOption pkgs "swww" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.swww" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.swww = {
      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "swww-daemon";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = "${lib.getExe' cfg.package "swww-daemon"}";
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
