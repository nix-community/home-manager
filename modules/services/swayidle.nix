{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.swayidle;

  mkTimeout = t:
    [ "timeout" (toString t.timeout) (escapeShellArg t.command) ]
    ++ optionals (t.resumeCommand != null) [
      "resume"
      (escapeShellArg t.resumeCommand)
    ];

  mkEvent = e: [ e.event (escapeShellArg e.command) ];

  args = cfg.extraArgs ++ (concatMap mkTimeout cfg.timeouts)
    ++ (concatMap mkEvent cfg.events);

in {
  meta.maintainers = [ maintainers.c0deaddict ];

  options.services.swayidle = let

    timeoutModule = { ... }: {
      options = {
        timeout = mkOption {
          type = types.ints.positive;
          example = 60;
          description = "Timeout in seconds.";
        };

        command = mkOption {
          type = types.str;
          description = "Command to run after timeout seconds of inactivity.";
        };

        resumeCommand = mkOption {
          type = with types; nullOr str;
          default = null;
          description = "Command to run when there is activity again.";
        };
      };
    };

    eventModule = { ... }: {
      options = {
        event = mkOption {
          type = types.enum [ "before-sleep" "after-resume" "lock" "unlock" ];
          description = "Event name.";
        };

        command = mkOption {
          type = types.str;
          description = "Command to run when event occurs.";
        };
      };
    };

  in {
    enable = mkEnableOption "idle manager for Wayland";

    package = mkOption {
      type = types.package;
      default = pkgs.swayidle;
      defaultText = literalExpression "pkgs.swayidle";
      description = "Swayidle package to install.";
    };

    timeouts = mkOption {
      type = with types; listOf (submodule timeoutModule);
      default = [ ];
      example = literalExpression ''
        [
          { timeout = 60; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
        ]
      '';
      description = "List of commands to run after idle timeout.";
    };

    events = mkOption {
      type = with types; listOf (submodule eventModule);
      default = [ ];
      example = literalExpression ''
        [
          { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock"; }
          { event = "lock"; command = "lock"; }
        ]
      '';
      description = "Run command on occurrence of a event.";
    };

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Extra arguments to pass to swayidle.";
    };

    systemdTarget = mkOption {
      type = types.str;
      default = "sway-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.swayidle" pkgs platforms.linux)
    ];

    systemd.user.services.swayidle = {
      Unit = {
        Description = "Idle manager for Wayland";
        Documentation = "man:swayidle(1)";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        # swayidle executes commands using "sh -c", so the PATH needs to contain a shell.
        Environment = [ "PATH=${makeBinPath [ pkgs.bash ]}" ];
        ExecStart =
          "${cfg.package}/bin/swayidle -w ${concatStringsSep " " args}";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
