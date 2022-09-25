{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.safeeyes;

in {
  meta.maintainers = [ hm.maintainers.rosuavio ];

  options = {
    services.safeeyes = {
      enable = mkEnableOption "The Safe Eyes OSGI service";

      package = mkPackageOption pkgs "safeeyes" { };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.safeeyes" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.safeeyes = {
      Install.WantedBy = [ "graphical-session.target" ];

      Unit = {
        Description = "Safe Eyes";
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 350;
        StartLimitBurst = 30;
      };

      Service = {
        ExecStart = getExe pkgs.safeeyes;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
