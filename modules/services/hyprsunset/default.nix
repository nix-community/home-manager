{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hyprsunset;
in
{
  meta.maintainers = with lib.maintainers; [
    khaneliman
  ];

  options.services.hyprsunset = {
    enable = lib.mkEnableOption "Hyprsunset, Hyprland's blue-light filter";

    package = lib.mkPackageOption pkgs "hyprsunset" { };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command-line arguments to pass to `hyprsunset`.";
      example = [
        "--identity"
      ];
    };

    transitions = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            calendar = lib.mkOption {
              type = lib.types.str;
              description = "Systemd calendar expression for when to run this transition.";
              example = "*-*-* 06:00:00";
            };

            requests = lib.mkOption {
              type = lib.types.listOf (lib.types.listOf lib.types.str);
              default = [ ];
              description = "List of requests to pass to `hyprctl hyprsunset` for this transition. Each inner list represents a separate command.";
              example = lib.literalExpression ''
                [
                  [ "temperature" "3500" ]
                ]
              '';
            };
          };
        }
      );
      default = { };
      description = "Set of transitions for different times of day (e.g., sunrise, sunset)";
      example = lib.literalExpression ''
        {
          sunrise = {
            calendar = "*-*-* 06:00:00";
            requests = [
              [ "temperature" "6500" ]
              [ "gamma 100" ]
            ];
          };
          sunset = {
            calendar = "*-*-* 19:00:00";
            requests = [
              [ "temperature" "3500" ]
            ];
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user =
      let
        # Create the main persistent service that maintains the IPC socket
        # Create a service for each transition in the transitions configuration
        # These services will send requests to the persistent service via IPC
        transitionServices = lib.mapAttrs' (
          name: transitionCfg:
          lib.nameValuePair "hyprsunset-${name}" {
            Install = { };

            Unit = {
              ConditionEnvironment = "WAYLAND_DISPLAY";
              Description = "hyprsunset transition for ${name}";
              After = [ "hyprsunset.service" ];
              Requires = [ "hyprsunset.service" ];
            };

            Service = {
              Type = "oneshot";
              # Execute multiple requests sequentially
              ExecStart = lib.concatMapStringsSep " && " (
                cmd:
                "${lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl"} hyprsunset ${lib.escapeShellArgs cmd}"
              ) transitionCfg.requests;
            };
          }
        ) cfg.transitions;
      in
      {
        services = {
          hyprsunset = {
            Install = {
              WantedBy = [ config.wayland.systemd.target ];
            };

            Unit = {
              ConditionEnvironment = "WAYLAND_DISPLAY";
              Description = "hyprsunset - Hyprland's blue-light filter";
              After = [ config.wayland.systemd.target ];
              PartOf = [ config.wayland.systemd.target ];
            };

            Service = {
              ExecStart = "${lib.getExe cfg.package} ${lib.escapeShellArgs cfg.extraArgs}";
              Restart = "always";
              RestartSec = "10";
            };
          };
        } // transitionServices;

        timers = lib.mapAttrs' (
          name: transitionCfg:
          lib.nameValuePair "hyprsunset-${name}" {
            Install = {
              WantedBy = [ config.wayland.systemd.target ];
            };

            Unit = {
              Description = "Timer for hyprsunset transition (${name})";
            };

            Timer = {
              OnCalendar = transitionCfg.calendar;
              Persistent = true;
            };
          }
        ) cfg.transitions;
      };
  };
}
