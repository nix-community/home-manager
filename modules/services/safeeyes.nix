{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.safeeyes;

in
{
  meta.maintainers = [ lib.hm.maintainers.rosuavio ];

  options = {
    services.safeeyes = {
      enable = lib.mkEnableOption "The Safe Eyes OSGI service";

      package = lib.mkPackageOption pkgs "safeeyes" { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.safeeyes" pkgs lib.platforms.linux)
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
        ExecStart = lib.getExe pkgs.safeeyes;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
