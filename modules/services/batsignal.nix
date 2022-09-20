{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.batsignal;

  commandLine = concatStringsSep " " ([ "${cfg.package}/bin/batsignal" ]
    ++ optional (cfg.warningLevelPercent != null)
    "-w ${toString cfg.warningLevelPercent}"
    ++ optional (cfg.criticalLevelPercent != null)
    "-c ${toString cfg.criticalLevelPercent}"
    ++ optional (cfg.criticalLevelPercent != null)
    "-d ${toString cfg.dangerLevelPercent}"
    ++ optional (cfg.fullLevelPercent != null)
    "-f ${toString cfg.fullLevelPercent}"
    ++ optional (cfg.warningLevelMessage != null)
    "-W '${cfg.warningLevelMessage}'"
    ++ optional (cfg.criticalLevelMessage != null)
    "-C '${cfg.criticalLevelMessage}'"
    ++ optional (cfg.dangerLevelCommand != null) (let
      cmd = pkgs.writeShellScript "batsignal-dangercmd" cfg.dangerLevelCommand;
    in "-D ${cmd}")
    ++ optional (cfg.fullLevelMessage != null) "-F '${cfg.fullLevelMessage}'"
    ++ optional (cfg.batteryNames != null)
    "-n '${concatStringsSep "," cfg.batteryNames}'"
    ++ optional (cfg.updateIntervalSeconds != null)
    "-m ${toString cfg.updateIntervalSeconds}"
    ++ optional (cfg.appName != null) "-a '${cfg.appName}'"
    ++ optional (cfg.icon != null) "-I ${cfg.icon}");

in {
  meta.maintainers = with maintainers; [ loicreynier ];

  options.services.batsignal = {
    enable = mkEnableOption "batsignal battery monitor daemon";
    package = mkPackageOption pkgs "batsignal" { };

    warningLevelPercent = mkOption {
      type = types.nullOr (types.ints.between 0 100);
      default = 15;
      example = 20;
      description = ''
        Warning level percentage of the battery capacity.
        0 disables this level.
      '';
    };

    criticalLevelPercent = mkOption {
      type = types.nullOr (types.ints.between 0 100);
      default = 5;
      example = 10;
      description = ''
        Critical level percentage of the battery capacity.
        0 disables this level.
      '';
    };

    dangerLevelPercent = mkOption {
      type = types.nullOr (types.ints.between 0 100);
      default = 2;
      example = 5;
      description = ''
        Danger level percentage of the battery capacity.
        0 disables this level.
      '';
    };

    fullLevelPercent = mkOption {
      type = types.nullOr (types.ints.between 0 100);
      default = 0;
      example = 95;
      description = ''
        Full level percentage of the battery capacity.
        0 disables this level.
      '';
    };

    warningLevelMessage = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = literalExpression ''
        Battery low
      '';
      description =
        "The message to show when the battery reaches the warning level.";
    };

    criticalLevelMessage = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = literalExpression ''
        Battery at critical level
      '';
      description =
        "The message to show when the battery reaches the critical level.";
    };

    dangerLevelCommand = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = ''
        notify-send "Battery at danger level"
      '';
      description = ''
        Command to execute when the battery capacity danger level is reached.
      '';
    };

    fullLevelMessage = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = literalExpression ''
        Battery full
      '';
      description = "Full level message.";
    };

    batteryNames = mkOption {
      type = types.listOf types.string;
      default = null;
      example = literalExpression ''
        [ "BAT0" ]
      '';
      description = "List of battery names";
    };

    updateIntervalSeconds = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      example = 60;
      description = ''
        Number of seconds between updates of the battery information.
      '';
    };

    appName = mkOption {
      type = types.nullOr types.string;
      default = null;
      example = "batsignal";
      description = ''
        Application name used in notifications.
      '';
    };

    icon = mkOption {
      type = types.nullOr types.string;
      default = null;
      example = "battery";
      description = ''
        Icon used in notifications.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.batsignal" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.batsignal = {
      Unit = {
        Description = "Battery monitor daemon";
        Documentation = "man:batsignal(1)";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Type = "simple";
        ExecStart = commandLine;
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
