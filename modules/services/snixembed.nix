{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.snixembed;
in {
  meta.maintainers = [ maintainers.DamienCassou ];

  options = {
    services.snixembed = {
      enable = mkEnableOption
        "snixembed: proxy StatusNotifierItems as XEmbedded systemtray-spec icons";

      package = mkPackageOption pkgs "snixembed" { };

      beforeUnits = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "safeeyes.service" ];
        description = ''
          List of other units that should be started after snixembed.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.snixembed" pkgs platforms.linux)
    ];

    systemd.user.services.snixembed = {
      Install.WantedBy = [ "graphical-session.target" ];

      Unit = {
        Description = "snixembed";
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 100;
        StartLimitBurst = 10;
        Before = cfg.beforeUnits;
      };

      Service = {
        ExecStart = getExe pkgs.snixembed;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
