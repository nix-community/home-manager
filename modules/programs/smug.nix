{ config, lib, pkgs, ... }:

let
  cfg = config.programs.smug;
  iniFormat = pkgs.formats.yaml { };

  mkOptionCommands = description:
    lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = description;
    };

  mkOptionRoot = description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = description;
    };

in {
  meta.maintainers = with lib.hm.maintainers; [ mipmip ];

  options.programs.smug = {

    enable = lib.mkEnableOption "Smug session manager";

    package = lib.mkPackageOption pkgs "smug" { nullable = true; };

    projects = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule [{
        options = {
          root = mkOptionRoot ''
            Root path in filesystem of the smug project. This is where tmux
            changes its directory to.

            Application defaults to `$HOME`.
          '';

          windows = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule [{
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Name of the tmux window;
                  '';
                };

                root = mkOptionRoot
                  "Root path of window. This is relative to the path of the smug project.";

                commands =
                  mkOptionCommands "Commands to execute when window starts.";

                layout = lib.mkOption {
                  type = lib.types.enum [
                    "main-horizontal"
                    "main-vertical"
                    "even-vertical"
                    "even-horizontal"
                    "tiled"
                  ];
                  description = ''
                    Layout of window when opening panes.
                  '';
                };

                manual = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  default = null;
                  description = ''
                    Start window only manually, using the -w arg
                  '';
                };

                panes = lib.mkOption {
                  default = null;
                  description = ''
                    Panes to open in a window.
                  '';
                  type = lib.types.nullOr (lib.types.listOf
                    (lib.types.submodule [{
                      options = {
                        root = mkOptionRoot
                          "Root path of pane. This is relative to the path of the smug project.";
                        commands = mkOptionCommands
                          "Commands to execute when pane starts.";
                        type = lib.mkOption {
                          type = lib.types.enum [ "horizontal" "vertical" ];
                          description = ''
                            Type of pane.
                          '';
                        };
                      };
                    }]));
                };
              };
            }]);
            description = ''
              Windows to create in the project session
            '';
          };

          env = lib.mkOption {
            type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
            default = null;
            description = "Environment Variables to set in session.";
          };

          beforeStart = mkOptionCommands
            "Commands to execute before the tmux-session starts.";

          stop = mkOptionCommands
            "Commands to execute after the tmux-session is destroyed.";
        };
      }]);
      default = { };
      description = "Attribute set with project configurations.";
    };
  };

  config = let
    cleanedProjects =
      lib.filterAttrsRecursive (name: value: value != null) cfg.projects;

    mkProjects = lib.attrsets.mapAttrs' (k: v: {
      name = "${config.home.homeDirectory}/.config/smug/${k}.yml";
      value.source = let
        prjConf = lib.attrsets.mapAttrs' (name: value:
          (lib.attrsets.nameValuePair
            (if name == "beforeStart" then "before_start" else name) (value))) v
          // {
            session = k;
            windows = lib.lists.forEach v.windows (winprop:
              (lib.filterAttrsRecursive (name: value: value != null) winprop));
          };
      in iniFormat.generate "smug-project-${k}" prjConf;
    });

  in lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    home.file = mkProjects cleanedProjects;
  };
}
