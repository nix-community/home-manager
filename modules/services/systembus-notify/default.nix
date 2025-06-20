{
  config,
  lib,
  pkgs,
  ...
}:

{
  meta.maintainers = [ lib.maintainers.asymmetric ];

  options = {
    services.systembus-notify = {
      enable = lib.mkEnableOption "systembus-notify - system bus notification daemon";
    };
  };

  config = lib.mkIf config.services.systembus-notify.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.systembus-notify" pkgs lib.platforms.linux)
    ];

    systemd.user.services.systembus-notify = {
      Unit.Description = "systembus-notify daemon";
      Install.WantedBy = [ "graphical-session.target" ];
      Service.ExecStart = "${pkgs.systembus-notify}/bin/systembus-notify";
    };
  };
}
