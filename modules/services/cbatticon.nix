{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.cbatticon;

  package = pkgs.cbatticon;

  makeCommand = commandName: commandArg:
    optional (commandArg != null)
    (let cmd = pkgs.writeShellScript commandName commandArg;
    in "--${commandName} ${cmd}");

  commandLine = concatStringsSep " " ([ "${package}/bin/cbatticon" ]
    ++ makeCommand "command-critical-level" cfg.commandCriticalLevel
    ++ makeCommand "command-left-click" cfg.commandLeftClick
    ++ optional (cfg.iconType != null) "--icon-type ${cfg.iconType}"
    ++ optional (cfg.lowLevelPercent != null)
    "--low-level ${toString cfg.lowLevelPercent}"
    ++ optional (cfg.criticalLevelPercent != null)
    "--critical-level ${toString cfg.criticalLevelPercent}"
    ++ optional (cfg.updateIntervalSeconds != null)
    "--update-interval ${toString cfg.updateIntervalSeconds}"
    ++ optional (cfg.hideNotification != null && cfg.hideNotification)
    "--hide-notification");

in {
  meta.maintainers = [ maintainers.pmiddend ];

  options = {
    services.cbatticon = {
      enable = mkEnableOption "cbatticon";

      commandCriticalLevel = mkOption {
        type = types.nullOr types.lines;
        default = null;
        example = ''
          notify-send "battery critical!"
        '';
        description = ''
          Command to execute when the critical battery level is reached.
        '';
      };

      commandLeftClick = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = ''
          Command to execute when left clicking on the tray icon.
        '';
      };

      iconType = mkOption {
        type =
          types.nullOr (types.enum [ "standard" "notification" "symbolic" ]);
        default = null;
        example = "symbolic";
        description = "Icon type to display in the system tray.";
      };

      lowLevelPercent = mkOption {
        type = types.nullOr (types.ints.between 0 100);
        default = null;
        example = 20;
        description = ''
          Low level percentage of the battery in percent (without the
          percent symbol).
        '';
      };

      criticalLevelPercent = mkOption {
        type = types.nullOr (types.ints.between 0 100);
        default = null;
        example = 5;
        description = ''
          Critical level percentage of the battery in percent (without
          the percent symbol).
        '';
      };

      updateIntervalSeconds = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 5;
        description = ''
          Number of seconds between updates of the battery information.
        '';
      };

      hideNotification = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Hide the notification popups.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.cbatticon" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ package ];

    systemd.user.services.cbatticon = {
      Unit = {
        Description = "cbatticon system tray battery icon";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = commandLine;
        Restart = "on-abort";
      };
    };
  };
}
