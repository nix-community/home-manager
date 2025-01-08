{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.aerospace;

  tomlFormat = pkgs.formats.toml { };

  filterAttrsRecursive = pred: set:
    lib.listToAttrs (lib.concatMap (name:
      let v = set.${name};
      in if pred v then
        [
          (lib.nameValuePair name (if lib.isAttrs v then
            filterAttrsRecursive pred v
          else if lib.isList v then
            (map (i: if lib.isAttrs i then filterAttrsRecursive pred i else i)
              (lib.filter pred v))
          else
            v))
        ]
      else
        [ ]) (lib.attrNames set));
  filterNulls = filterAttrsRecursive (v: v != null);
in {
  meta.maintainers = with hm.maintainers; [ damidoug ];

  options.programs.aerospace = with types; {
    enable = mkEnableOption "Whether to enable AeroSpace window manager.";

    package = mkPackageOption pkgs "aerospace" { };

    userSettings = mkOption {
      type = submodule {
        freeformType = tomlFormat.type;
        options = {
          start-at-login = lib.mkOption {
            type = bool;
            default = false;
            description = "Start AeroSpace at login.";
          };
          after-login-command = mkOption {
            type = listOf str;
            default = [ ];
            description = ''
              You can use it to add commands that run after login to macOS user session.
              'start-at-login' needs to be 'true' for 'after-login-command' to work.
            '';
          };
          after-startup-command = mkOption {
            type = listOf str;
            default = [ ];
            description = ''
              You can use it to add commands that run after AeroSpace startup.
              'after-startup-command' is run after 'after-login-command'
            '';
            example = [ "layout tiles" ];
          };
          enable-normalization-flatten-containers = mkOption {
            type = bool;
            default = true;
            description =
              ''Containers that have only one child are "flattened".'';
          };
          enable-normalization-opposite-orientation-for-nested-containers =
            mkOption {
              type = bool;
              default = true;
              description =
                "Containers that nest into each other must have opposite orientations.";
            };
          accordion-padding = mkOption {
            type = int;
            default = 30;
            description = "Padding between windows in an accordion container.";
          };
          default-root-container-layout = mkOption {
            type = enum [ "tiles" "accordion" ];
            default = "tiles";
            description = "Default layout for the root container.";
          };
          default-root-container-orientation = mkOption {
            type = enum [ "horizontal" "vertical" "auto" ];
            default = "auto";
            description = "Default orientation for the root container.";
          };
          on-window-detected = mkOption {
            type = listOf (submodule {
              options = {
                "if" = mkOption {
                  type = submodule {
                    options = {
                      app-id = mkOption {
                        type = nullOr str;
                        default = null;
                        description = "The application ID to match (optional).";
                      };
                      workspace = mkOption {
                        type = nullOr str;
                        default = null;
                        description = "The workspace name to match (optional).";
                      };
                      window-title-regex-substring = mkOption {
                        type = nullOr str;
                        default = null;
                        description =
                          "Substring to match in the window title (optional).";
                      };
                      app-name-regex-substring = mkOption {
                        type = nullOr str;
                        default = null;
                        description =
                          "Regex substring to match the app name (optional).";
                      };
                      during-aerospace-startup = mkOption {
                        type = nullOr bool;
                        default = null;
                        description =
                          "Whether to match during aerospace startup (optional).";
                      };
                    };
                  };
                  default = { };
                  description = "Conditions for detecting a window.";
                };
                check-further-callbacks = mkOption {
                  type = nullOr bool;
                  default = null;
                  description =
                    "Whether to check further callbacks after this rule (optional).";
                };
                run = mkOption {
                  type = oneOf [ str (listOf str) ];
                  example = [ "move-node-to-workspace m" "resize-node" ];
                  description =
                    "Commands to execute when the conditions match (required).";
                };
              };
            });
            default = [ ];
            example = [{
              "if" = {
                app-id = "Another.Cool.App";
                workspace = "cool-workspace";
                window-title-regex-substring = "Title";
                app-name-regex-substring = "CoolApp";
                during-aerospace-startup = false;
              };
              check-further-callbacks = false;
              run = [ "move-node-to-workspace m" "resize-node" ];
            }];
            description =
              "Commands to run every time a new window is detected with optional conditions.";
          };
          workspace-to-monitor-force-assignment = mkOption {
            type = attrsOf (oneOf [ int str (listOf str) ]);
            default = { };
            description = ''
              Map workspaces to specific monitors.
              Left-hand side is the workspace name, and right-hand side is the monitor pattern.
            '';
            example = {
              "1" = 1; # First monitor from left to right.
              "2" = "main"; # Main monitor.
              "3" = "secondary"; # Secondary monitor (non-main).
              "4" = "built-in"; # Built-in display.
              "5" =
                "^built-in retina display$"; # Regex for the built-in retina display.
              "6" = [ "secondary" "dell" ]; # Match first pattern in the list.
            };
          };
          on-focus-changed = mkOption {
            type = listOf str;
            default = [ ];
            example = [ "move-mouse monitor-lazy-center" ];
            description =
              "Commands to run every time focused window or workspace changes.";
          };
          on-focused-monitor-changed = mkOption {
            type = listOf str;
            default = [ "move-mouse monitor-lazy-center" ];
            description = "Commands to run every time focused monitor changes.";
          };
          exec-on-workspace-change = mkOption {
            type = listOf str;
            default = [ ];
            example = [
              "/bin/bash"
              "-c"
              "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
            ];
            description = "Commands to run every time workspace changes.";
          };
          key-mapping.preset = mkOption {
            type = enum [ "qwerty" "dvorak" ];
            default = "qwerty";
            description = "Keymapping preset.";
          };
        };
      };
      default = { };
      example = literalExpression ''
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
        <link xlink:href="https://nikitabobko.github.io/AeroSpace/guide#configuring-aerospace"/>
        for supported values.
      '';
    };
  };

  config.home = mkIf cfg.enable {
    packages = [ cfg.package ];
    file.".config/aerospace/aerospace.toml".source =
      tomlFormat.generate "aerospace" (filterNulls cfg.userSettings);
  };

}
