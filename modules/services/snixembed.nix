{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.snixembed;
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options = {
    services.snixembed = {
      enable = lib.mkEnableOption "snixembed: proxy StatusNotifierItems as XEmbedded systemtray-spec icons";

      package = lib.mkPackageOption pkgs "snixembed" { };

      beforeUnits = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [ "safeeyes.service" ];
        description = ''
          List of other units that should be started after snixembed.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.snixembed" pkgs lib.platforms.linux)
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
        ExecStart = lib.getExe pkgs.snixembed;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
