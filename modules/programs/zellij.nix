{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.zellij;
  yamlFormat = pkgs.formats.yaml { };

  mkShellIntegrationOption =
    option:
    option
    // {
      default = false;
      example = true;
    };
in
{
  meta.maintainers = [
    lib.maintainers.khaneliman
    lib.hm.maintainers.mainrs
  ];

  options.programs.zellij = {
    enable = lib.mkEnableOption "Zellij";

    package = lib.mkPackageOption pkgs "zellij" { };

    layouts = lib.mkOption {
      type = types.attrsOf (
        types.oneOf [
          yamlFormat.type
          types.path
          types.lines
        ]
      );
      default = { };
      example = lib.literalExpression ''
        {
          dev = {
            layout = {
              _children = [
                {
                  default_tab_template = {
                    _children = [
                      {
                        pane = {
                          size = 1;
                          borderless = true;
                          plugin = {
                            location = "zellij:tab-bar";
                          };
                        };
                      }
                      { "children" = { }; }
                      {
                        pane = {
                          size = 2;
                          borderless = true;
                          plugin = {
                            location = "zellij:status-bar";
                          };
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Project";
                      focus = true;
                    };
                    _children = [
                      {
                        pane = {
                          command = "nvim";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Git";
                    };
                    _children = [
                      {
                        pane = {
                          command = "lazygit";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Files";
                    };
                    _children = [
                      {
                        pane = {
                          command = "yazi";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Shell";
                    };
                    _children = [
                      {
                        pane = {
                          command = "zsh";
                        };
                      }
                    ];
                  };
                }
              ];
            };
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/zellij/layouts/<layout>.kdl`.

        See <https://zellij.dev/documentation> for the full
        list of options.
      '';
    };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "custom";
          themes.custom.fg = "#ffffff";
          keybinds._props.clear-defaults = true;
          keybinds.pane._children = [
            {
              bind = {
                _args = ["e"];
                _children = [
                  { TogglePaneEmbedOrFloating = {}; }
                  { SwitchToMode._args = ["locked"]; }
                ];
              };
            }
            {
              bind = {
                _args = ["left"];
                MoveFocus = ["left"];
              };
            }
          ];
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/zellij/config.kdl`.

        If `programs.zellij.package.version` is older than 0.32.0, then
        the configuration is written to {file}`$XDG_CONFIG_HOME/zellij/config.yaml`.

        See <https://zellij.dev/documentation> for the full
        list of options.
      '';
    };

    attachExistingSession = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to attach to the default session after being autostarted if a Zellij session already exists.

        Variable is checked in `auto-start` script. Requires shell integration to be enabled to have effect.
      '';
    };

    exitShellOnExit = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to exit the shell when Zellij exits after being autostarted.

        Variable is checked in `auto-start` script. Requires shell integration to be enabled to have effect.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (
        types.oneOf [
          yamlFormat.type
          types.path
          types.lines
        ]
      );
      default = { };
      description = ''
        Each them is written to {file}`$XDG_CONFIG_HOME/zellij/themes/NAME.kdl`.
        See <https://zellij.dev/documentation/themes.html> for more information.
      '';
    };

    enableBashIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkBashIntegrationOption { inherit config; }
    );

    enableFishIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkFishIntegrationOption { inherit config; }
    );

    enableZshIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkZshIntegrationOption { inherit config; }
    );
  };

  config =
    let
      shellIntegrationEnabled = (
        cfg.enableBashIntegration || cfg.enableZshIntegration || cfg.enableFishIntegration
      );
    in
    mkIf cfg.enable {
      home.packages = [ cfg.package ];

      # Zellij switched from yaml to KDL in version 0.32.0:
      # https://github.com/zellij-org/zellij/releases/tag/v0.32.0
      xdg.configFile = lib.mkMerge [
        {
          "zellij/config.yaml" =
            mkIf (cfg.settings != { } && (lib.versionOlder cfg.package.version "0.32.0"))
              {
                source = yamlFormat.generate "zellij.yaml" cfg.settings;
              };
          "zellij/config.kdl" =
            mkIf (cfg.settings != { } && (lib.versionAtLeast cfg.package.version "0.32.0"))
              {
                text = lib.hm.generators.toKDL { } cfg.settings;
              };
        }

        (lib.mapAttrs' (
          name: value:
          lib.nameValuePair "zellij/layouts/${name}.kdl" {
            source =
              if builtins.isPath value || lib.isStorePath value then
                value
              else
                pkgs.writeText "zellij-layout-${name}" (
                  if lib.isString value then value else lib.hm.generators.toKDL { } value
                );
          }
        ) cfg.layouts)

        (lib.mapAttrs' (
          name: value:
          lib.nameValuePair "zellij/themes/${name}.kdl" {
            source =
              if builtins.isPath value || lib.isStorePath value then
                value
              else
                pkgs.writeText "zellij-theme-${name}" (
                  if lib.isString value then value else lib.hm.generators.toKDL { } value
                );
          }
        ) cfg.themes)
      ];

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        eval "$(${lib.getExe cfg.package} setup --generate-auto-start bash)"
      '';

      programs.zsh.initContent = mkIf cfg.enableZshIntegration (
        lib.mkOrder 200 ''
          eval "$(${lib.getExe cfg.package} setup --generate-auto-start zsh)"
        ''
      );

      programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        eval (${lib.getExe cfg.package} setup --generate-auto-start fish | string collect)
      '';

      home.sessionVariables = mkIf shellIntegrationEnabled {
        ZELLIJ_AUTO_ATTACH = if cfg.attachExistingSession then "true" else "false";
        ZELLIJ_AUTO_EXIT = if cfg.exitShellOnExit then "true" else "false";
      };

      warnings =
        lib.optional (cfg.attachExistingSession && !shellIntegrationEnabled) ''
          You have enabled `programs.zellij.attachExistingSession`, but none of the shell integrations are enabled.
          This option will have no effect.
        ''
        ++ lib.optional (cfg.exitShellOnExit && !shellIntegrationEnabled) ''
          You have enabled `programs.zellij.exitShellOnExit`, but none of the shell integrations are enabled.
          This option will have no effect.
        '';
    };
}
