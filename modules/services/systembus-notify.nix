{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.systembus-notify;
in
{
  meta.maintainers = [ lib.maintainers.asymmetric ];

  options = {
    services.systembus-notify = {
      enable = lib.mkEnableOption "systembus-notify - system bus notification daemon";

      package = lib.mkPackageOption pkgs "systembus-notify" { };
    };
  };

  config = lib.mkIf config.services.systembus-notify.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.systembus-notify" pkgs lib.platforms.linux)
    ];

    systemd.user.services.systembus-notify = {
      Unit.Description = "systembus-notify daemon";
      Install.WantedBy = [ "graphical-session.target" ];
      Service.ExecStart = lib.getExe cfg.package;
    };
  };
}
