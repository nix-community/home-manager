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
        "--verbose"
      ];
    };

    transitions = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            calendar = lib.mkOption {
              type = lib.types.str;
              description = ''
                Deprecated - Use {option}`services.hyprsunset.settings` instead to manage transitions.

                Systemd calendar expression for when to run this transition.
              '';
              example = "*-*-* 06:00:00";
            };

            requests = lib.mkOption {
              type = lib.types.listOf (lib.types.listOf lib.types.str);
              default = [ ];
              description = ''
                Deprecated - Use {option}`services.hyprsunset.settings` instead to manage transitions.

                List of requests to pass to `hyprctl hyprsunset` for this transition. Each inner list represents a separate command.
              '';
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
      description = ''
        Deprecated - Use {option}`services.hyprsunset.settings` instead to manage transitions.

        Set of transitions for different times of day (e.g., sunrise, sunset)
      '';
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

    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              path
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "Hyprsunset configuration value";
            };
        in
        valueType;
      default = { };
      description = ''
        Hyprsunset configuration written in Nix. Entries with the same key
        should be written as lists. Variables' and colors' names should be
        quoted. See <https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/> for more examples.
      '';
      example = lib.literalExpression ''
        {
          max-gamma = 150;

          profile = [
            {
              time = "7:30";
              identity = true;
            }
            {
              time = "21:00";
              temperature = 5000;
              gamma = 0.8;
            }
          ];
        };
      '';
    };

    importantPrefixes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "$" ];
      example = [ "$" ];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = config.wayland.systemd.target;
      defaultText = lib.literalExpression "config.wayland.systemd.target";
      example = "hyprland-session.target";
      description = "Systemd target to bind to.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.wayland.windowManager.hyprland.package != null || cfg.transitions == { };
        message = ''
          Can't set services.hyprsunset.enable when using the deprecated option
          services.hyprsunset.transitions if wayland.windowManager.hyprland.package
          is set to null. Either migrate your configuration to use services.hyprsunset.settings
          or, if you are using Hyprland's upstream flake, see:
          <https://github.com/nix-community/home-manager/issues/7484>.
        '';
      }
    ];

    warnings = lib.mkIf (cfg.transitions != { }) [
      ''
        Using services.hyprsunset.transitions is deprecated. Please use
        services.hyprsunset.settings instead.
      ''
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."hypr/hyprsunset.conf" = lib.mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf {
        attrs = cfg.settings;
        inherit (cfg) importantPrefixes;
      };
    };

    systemd.user = {
      services = {
        hyprsunset = {
          Install = {
            WantedBy = [ cfg.systemdTarget ];
          };

          Unit = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "hyprsunset - Hyprland's blue-light filter";
            After = [ config.wayland.systemd.target ];
            PartOf = [ config.wayland.systemd.target ];
            X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
              "${config.xdg.configFile."hypr/hyprsunset.conf".source}"
            ];
          };

          Service = {
            ExecStart = "${lib.getExe cfg.package}${
              lib.optionalString (cfg.extraArgs != [ ]) " ${lib.escapeShellArgs cfg.extraArgs}"
            }";
            Restart = "always";
            RestartSec = "10";
          };
        };
      }
      // lib.optionalAttrs (config.wayland.windowManager.hyprland.package != null) lib.mapAttrs' (
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
