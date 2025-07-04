{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.aerospace;

  tomlFormat = pkgs.formats.toml { };

  # filterAttrsRecursive supporting lists, as well.
  filterListAndAttrsRecursive =
    pred: set:
    lib.listToAttrs (
      lib.concatMap (
        name:
        let
          v = set.${name};
        in
        if pred v then
          [
            (lib.nameValuePair name (
              if lib.isAttrs v then
                filterListAndAttrsRecursive pred v
              else if lib.isList v then
                (map (i: if lib.isAttrs i then filterListAndAttrsRecursive pred i else i) (lib.filter pred v))
              else
                v
            ))
          ]
        else
          [ ]
      ) (lib.attrNames set)
    );
  filterNulls = filterListAndAttrsRecursive (v: v != null);
in
{
  meta.maintainers = with lib.maintainers; [ damidoug ];

  options.programs.aerospace = {
    enable = lib.mkEnableOption "AeroSpace window manager";

    package = lib.mkPackageOption pkgs "aerospace" { nullable = true; };

    launchd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Configure the launchd agent to manage the AeroSpace process.

          The first time this is enabled, macOS will prompt you to allow this background
          item in System Settings.

          You can verify the service is running correctly from your terminal.
          Run: `launchctl list | grep aerospace`

          - A running process will show a Process ID (PID) and a status of 0, for example:
            `12345	0	org.nix-community.home.aerospace`

          - If the service has crashed or failed to start, the PID will be a dash and the
            status will be a non-zero number, for example:
            `-	1	org.nix-community.home.aerospace`

          In case of failure, check the logs with `cat /tmp/aerospace.err.log`.

          For more detailed service status, run `launchctl print gui/$(id -u)/org.nix-community.home.aerospace`.

          NOTE: Enabling this option will configure AeroSpace to **not** manage its own
          launchd agent. Specifically, it will set `start-at-login = false` and
          `after-login-command = []` in the configuration file, as those are now handled
          by Home Manager and launchd instead.
        '';
      };
      keepAlive = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the launchd service should be kept alive.";
      };
    };

    userSettings = mkOption {
      type = types.submodule {
        freeformType = tomlFormat.type;
        options = {
          after-startup-command = mkOption {
            type = with types; listOf str;
            default = [ ];
            description = ''
              A list of AeroSpace commands to execute immediately after the AeroSpace application starts.
              These commands are written to your `aerospace.toml` config file and are run after the `after-login-command` sequence.

              A list of all available commands can be found at <https://nikitabobko.github.io/AeroSpace/commands>.

              While this module checks for valid command names, using incorrect *arguments* can still cause issues.
              If AeroSpace is not behaving correctly after startup, check the logs for errors with `cat /tmp/aerospace.err.log`.
            '';
            example = [
              "exec-and-forget open -n /System/Applications/Utilities/Terminal.app"
              "layout tiles accordion"
            ];
          };
          enable-normalization-flatten-containers = mkOption {
            type = types.bool;
            default = true;
            description = ''Containers that have only one child are "flattened".'';
          };
          enable-normalization-opposite-orientation-for-nested-containers = mkOption {
            type = types.bool;
            default = true;
            description = "Containers that nest into each other must have opposite orientations.";
          };
          accordion-padding = mkOption {
            type = types.int;
            default = 30;
            description = "Padding between windows in an accordion container.";
          };
          default-root-container-layout = mkOption {
            type = types.enum [
              "tiles"
              "accordion"
            ];
            default = "tiles";
            description = "Default layout for the root container.";
          };
          default-root-container-orientation = mkOption {
            type = types.enum [
              "horizontal"
              "vertical"
              "auto"
            ];
            default = "auto";
            description = "Default orientation for the root container.";
          };
          on-window-detected = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  "if" = mkOption {
                    type = types.submodule {
                      options = {
                        app-id = mkOption {
                          type = with types; nullOr str;
                          default = null;
                          description = "The application ID to match (optional).";
                        };
                        workspace = mkOption {
                          type = with types; nullOr str;
                          default = null;
                          description = "The workspace name to match (optional).";
                        };
                        window-title-regex-substring = mkOption {
                          type = with types; nullOr str;
                          default = null;
                          description = "Substring to match in the window title (optional).";
                        };
                        app-name-regex-substring = mkOption {
                          type = with types; nullOr str;
                          default = null;
                          description = "Regex substring to match the app name (optional).";
                        };
                        during-aerospace-startup = mkOption {
                          type = with types; nullOr bool;
                          default = null;
                          description = "Whether to match during aerospace startup (optional).";
                        };
                      };
                    };
                    default = { };
                    description = "Conditions for detecting a window.";
                  };
                  check-further-callbacks = mkOption {
                    type = with types; nullOr bool;
                    default = null;
                    description = "Whether to check further callbacks after this rule (optional).";
                  };
                  run = mkOption {
                    type =
                      with types;
                      oneOf [
                        str
                        (listOf str)
                      ];
                    example = [
                      "move-node-to-workspace m"
                      "resize-node"
                    ];
                    description = "Commands to execute when the conditions match (required).";
                  };
                };
              }
            );
            default = [ ];
            example = [
              {
                "if" = {
                  app-id = "Another.Cool.App";
                  workspace = "cool-workspace";
                  window-title-regex-substring = "Title";
                  app-name-regex-substring = "CoolApp";
                  during-aerospace-startup = false;
                };
                check-further-callbacks = false;
                run = [
                  "move-node-to-workspace m"
                  "resize-node"
                ];
              }
            ];
            description = "Commands to run every time a new window is detected with optional conditions.";
          };
          workspace-to-monitor-force-assignment = mkOption {
            type =
              with types;
              nullOr (
                attrsOf (oneOf [
                  int
                  str
                  (listOf str)
                ])
              );
            default = null;
            description = ''
              Map workspaces to specific monitors.
              Left-hand side is the workspace name, and right-hand side is the monitor pattern.
            '';
            example = {
              "1" = 1; # First monitor from left to right.
              "2" = "main"; # Main monitor.
              "3" = "secondary"; # Secondary monitor (non-main).
              "4" = "built-in"; # Built-in display.
              "5" = "^built-in retina display$"; # Regex for the built-in retina display.
              "6" = [
                "secondary"
                "dell"
              ]; # Match first pattern in the list.
            };
          };
          on-focus-changed = mkOption {
            type = with types; listOf str;
            default = [ ];
            example = [ "move-mouse monitor-lazy-center" ];
            description = "Commands to run every time focused window or workspace changes.";
          };
          on-focused-monitor-changed = mkOption {
            type = with types; listOf str;
            default = [ "move-mouse monitor-lazy-center" ];
            description = "Commands to run every time focused monitor changes.";
          };
          exec-on-workspace-change = mkOption {
            type = with types; listOf str;
            default = [ ];
            example = [
              "/bin/bash"
              "-c"
              "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
            ];
            description = "Commands to run every time workspace changes.";
          };
          key-mapping.preset = mkOption {
            type = types.enum [
              "qwerty"
              "dvorak"
            ];
            default = "qwerty";
            description = "Keymapping preset.";
          };
        };
      };
      default = { };
      example = lib.literalExpression ''
        {
          gaps = {
            outer.left = 8;
            outer.bottom = 8;
            outer.top = 8;
            outer.right = 8;
          };
          mode.main.binding = {
            alt-h = "focus left";
            alt-j = "focus down";
            alt-k = "focus up";
            alt-l = "focus right";
          };
        }
      '';
      description = ''
        AeroSpace configuration, see
        <https://nikitabobko.github.io/AeroSpace/guide#configuring-aerospace>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.aerospace" pkgs lib.platforms.darwin)
    ];

    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file.".config/aerospace/aerospace.toml".source = tomlFormat.generate "aerospace" (
        filterNulls (
          cfg.userSettings
          // lib.optionalAttrs cfg.launchd.enable {
            # Override these to avoid launchd conflicts
            start-at-login = false;
            after-login-command = [ ];
          }
        )
      );
    };

    launchd.agents.aerospace = {
      enable = cfg.launchd.enable;
      config = {
        Program = "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
        KeepAlive = cfg.launchd.keepAlive;
        RunAtLoad = true;
        StandardOutPath = "/tmp/aerospace.log";
        StandardErrorPath = "/tmp/aerospace.err.log";
      };
    };
  };
}
