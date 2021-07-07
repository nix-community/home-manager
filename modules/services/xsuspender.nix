{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xsuspender;

  iniFormat = pkgs.formats.ini { };

  xsuspenderOptions = types.submodule {
    options = {
      matchWmClassContains = mkOption {
        description = "Match windows that wm class contains string.";
        type = types.nullOr types.str;
        default = null;
      };

      matchWmClassGroupContains = mkOption {
        description = "Match windows where wm class group contains string.";
        type = types.nullOr types.str;
        default = null;
      };

      matchWmNameContains = mkOption {
        description = "Match windows where wm name contains string.";
        type = types.nullOr types.str;
        default = null;
      };

      suspendDelay = mkOption {
        description = "Initial suspend delay in seconds.";
        type = types.int;
        default = 5;
      };

      resumeEvery = mkOption {
        description = "Resume interval in seconds.";
        type = types.int;
        default = 50;
      };

      resumeFor = mkOption {
        description = "Resume duration in seconds.";
        type = types.int;
        default = 5;
      };

      execSuspend = mkOption {
        description = ''
          Before suspending, execute this shell script. If it fails,
          abort suspension.
        '';
        type = types.nullOr types.str;
        default = null;
        example = ''echo "suspending window $XID of process $PID"'';
      };

      execResume = mkOption {
        description = ''
          Before resuming, execute this shell script. Resume the
          process regardless script failure.
        '';
        type = types.nullOr types.str;
        default = null;
        example = "echo resuming ...";
      };

      sendSignals = mkOption {
        description = ''
          Whether to send SIGSTOP / SIGCONT signals or not.
          If false just the exec scripts are run.
        '';
        type = types.bool;
        default = true;
      };

      suspendSubtreePattern = mkOption {
        description =
          "Also suspend descendant processes that match this regex.";
        type = types.nullOr types.str;
        default = null;
      };

      onlyOnBattery = mkOption {
        description = "Whether to enable process suspend only on battery.";
        type = types.bool;
        default = false;
      };

      autoSuspendOnBattery = mkOption {
        description = ''
          Whether to auto-apply rules when switching to battery
          power even if the window(s) didn't just lose focus.
        '';
        type = types.bool;
        default = true;
      };

      downclockOnBattery = mkOption {
        description = ''
          Limit CPU consumption for this factor when on battery power.
          Value 1 means 50% decrease, 2 means 66%, 3 means 75% etc.
        '';
        type = types.int;
        default = 0;
      };
    };
  };

in {
  meta.maintainers = [ maintainers.offline ];

  options = {
    services.xsuspender = {
      enable = mkEnableOption "XSuspender";

      defaults = mkOption {
        description = "XSuspender defaults.";
        type = xsuspenderOptions;
        default = { };
      };

      rules = mkOption {
        description = "Attribute set of XSuspender rules.";
        type = types.attrsOf xsuspenderOptions;
        default = { };
        example = {
          Chromium = {
            suspendDelay = 10;
            matchWmClassContains = "chromium-browser";
            suspendSubtreePattern = "chromium";
          };
        };
      };

      debug = mkOption {
        description = "Whether to enable debug output.";
        type = types.bool;
        default = false;
      };

      iniContent = mkOption {
        type = iniFormat.type;
        internal = true;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xsuspender" pkgs
        lib.platforms.linux)
    ];

    services.xsuspender.iniContent = let
      mkSection = values:
        filterAttrs (_: v: v != null) {
          match_wm_class_contains = values.matchWmClassContains;
          match_wm_class_group_contains = values.matchWmClassGroupContains;
          match_wm_name_contains = values.matchWmNameContains;
          suspend_delay = values.suspendDelay;
          resume_every = values.resumeEvery;
          resume_for = values.resumeFor;
          exec_suspend = values.execSuspend;
          exec_resume = values.execResume;
          send_signals = values.sendSignals;
          suspend_subtree_pattern = values.suspendSubtreePattern;
          only_on_battery = values.onlyOnBattery;
          auto_suspend_on_battery = values.autoSuspendOnBattery;
          downclock_on_battery = values.downclockOnBattery;
        };
    in {
      Default = mkSection cfg.defaults;
    } // mapAttrs (_: mkSection) cfg.rules;

    # To make the xsuspender tool available.
    home.packages = [ pkgs.xsuspender ];

    xdg.configFile."xsuspender.conf".source =
      iniFormat.generate "xsuspender.conf" cfg.iniContent;

    systemd.user.services.xsuspender = {
      Unit = {
        Description = "XSuspender";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers =
          [ "${config.xdg.configFile."xsuspender.conf".source}" ];
      };

      Service = {
        ExecStart = "${pkgs.xsuspender}/bin/xsuspender";
        Environment = mkIf cfg.debug [ "G_MESSAGE_DEBUG=all" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
