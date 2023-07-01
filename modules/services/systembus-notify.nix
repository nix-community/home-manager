{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.asymmetric ];

  options = {
    services.systembus-notify = {
      enable =
        mkEnableOption "systembus-notify - system bus notification daemon";
    };
  };

  config = mkIf config.services.systembus-notify.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.systembus-notify" pkgs
        platforms.linux)
    ];

    systemd.user.services.systembus-notify = {
      Unit.Description = "systembus-notify daemon";
      Install.WantedBy = [ "graphical-session.target" ];
      Service.ExecStart = "${pkgs.systembus-notify}/bin/systembus-notify";
    };
  };
}
