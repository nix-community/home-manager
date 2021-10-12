# Wrapper around xidlehook.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xidlehook;

  notEmpty = list: filter (x: x != "" && x != null) (flatten list);

  timers = let
    toTimer = timer:
      "--timer ${toString timer.delay} ${
        escapeShellArgs [ timer.command timer.canceller ]
      }";
  in map toTimer (filter (timer: timer.command != null) cfg.timers);

  script = pkgs.writeShellScript "xidlehook" ''
    ${concatStringsSep "\n"
    (mapAttrsToList (name: value: "export ${name}=${value}")
      cfg.environment or { })}
    ${concatStringsSep " " (notEmpty [
      "${cfg.package}/bin/xidlehook"
      (optionalString cfg.once "--once")
      (optionalString cfg.not-when-fullscreen "--not-when-fullscreen")
      (optionalString cfg.not-when-audio "--not-when-audio")
      timers
    ])}
  '';
in {
  meta.maintainers = [ maintainers.dschrempf ];

  options.services.xidlehook = {
    enable = mkEnableOption "xidlehook systemd service";

    package = mkOption {
      type = types.package;
      default = pkgs.xidlehook;
      defaultText = "pkgs.xidlehook";
      description = "The package to use for xidlehook.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          "primary-display" = "$(xrandr | awk '/ primary/{print $1}')";
        }
      '';
      description = ''
        Extra environment variables to be exported in the script.
        These options are passed unescaped as <code>export name=value</code>.
      '';
    };

    not-when-fullscreen = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Disable locking when a fullscreen application is in use.";
    };

    not-when-audio = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Disable locking when audio is playing.";
    };

    once = mkEnableOption "running the program once and exiting";

    timers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          delay = mkOption {
            type = types.ints.unsigned;
            example = 60;
            description = "Time before executing the command.";
          };
          command = mkOption {
            type = types.nullOr types.str;
            example = literalExpression ''
              ''${pkgs.libnotify}/bin/notify-send "Idle" "Sleeping in 1 minute"
            '';
            description = ''
              Command executed after the idle timeout is reached.
              Path to executables are accepted.
              The command is automatically escaped.
            '';
          };
          canceller = mkOption {
            type = types.str;
            default = "";
            example = literalExpression ''
              ''${pkgs.libnotify}/bin/notify-send "Idle" "Resuming activity"
            '';
            description = ''
              Command executed when the user becomes active again.
              This is only executed if the next timer has not been reached.
              Path to executables are accepted.
              The command is automatically escaped.
            '';
          };
        };
      });
      default = [ ];
      example = literalExpression ''
        [
          {
            delay = 60;
            command = "xrandr --output \"$PRIMARY_DISPLAY\" --brightness .1";
            canceller = "xrandr --output \"$PRIMARY_DISPLAY\" --brightness 1";
          }
          {
            delay = 120;
            command = "''${pkgs.writeShellScript "my-script" '''
              # A complex script to run
            '''}";
          }
        ]
      '';
      description = ''
        A set of commands to be executed after a specific idle timeout.
        The commands specified in <literal>command</literal> and <literal>canceller</literal>
        are passed escaped to the script.
        To use or re-use environment variables that are script-dependent, specify them
        in the <literal>environment</literal> section.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xidlehook" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.xidlehook = {
      Unit = {
        Description = "xidlehook service";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = [ "DISPLAY" ];
      };
      Service = {
        Type = if cfg.once then "oneshot" else "simple";
        ExecStart = "${script}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
