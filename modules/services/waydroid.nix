{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.waydroid;

in {
  options.services.waydroid.enable = mkEnableOption "Waydroid Android container";

  config = mkIf cfg.enable {

    systemd.user.services.waydroid-session = {
      Unit = {
        Description = "Waydroid user session";
        Requires = [ "waydroid-container.service" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart =
          "${pkgs.waydroid}/bin/waydroid session start";
        Restart = "always";
        RestartSec = 12;
      };
    };
  };
}
