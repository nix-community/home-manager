{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zellij;
  yamlFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.zellij = {
    enable = mkEnableOption "zellij";

    package = mkOption {
      type = types.package;
      default = pkgs.zellij;
      defaultText = literalExpression "pkgs.zellij";
      description = ''
        The zellij package to install.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "custom";
          themes.custom.fg = "#ffffff";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/zellij/config.yaml`.

        See <https://zellij.dev/documentation> for the full
        list of options.
      '';
    };

    layouts = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExpression ''
        {
          # redefining the default layout
          default = '''
            layout {
              pane size=1 borderless=true {
                plugin location=\"zellij:tab-bar\"
              }
              pane
              pane size=2 borderless=true {
                plugin location=\"zellij:status-bar\"
              }
            }
          '''
        }
      '';
      description = ''
        A set of zellij layouts written to {file}`$XDG_CONFIG_HOME/zellij/layouts/`.
        Each key corresponds to one layout with the key being its name.

        See <https://zellij.dev/documentation/layouts> for the full list of options.
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = false;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = false;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Zellij switched from yaml to KDL in version 0.32.0:
    # https://github.com/zellij-org/zellij/releases/tag/v0.32.0
    xdg.configFile = let
      config = {
        "zellij/config.yaml" = mkIf
          (cfg.settings != { } && (versionOlder cfg.package.version "0.32.0")) {
            source = yamlFormat.generate "zellij.yaml" cfg.settings;
          };
        "zellij/config.kdl" = mkIf (cfg.settings != { }
          && (versionAtLeast cfg.package.version "0.32.0")) {
            text = lib.hm.generators.toKDL { } cfg.settings;
          };
      };

      extension =
        if (versionOlder cfg.package.version "0.32.0") then "yaml" else "kdl";
      layouts = builtins.trace cfg lib.mapAttrs' (name: layout: {
        name = "zellij/layouts/${name}.${extension}";
        value = {
          source = pkgs.writeText "zellij-layout-${name}.${extension}" layout;
        };
      }) cfg.layouts;
    in config // layouts;

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkOrder 200 ''
      eval "$(zellij setup --generate-auto-start bash)"
    '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration (mkOrder 200 ''
      eval "$(zellij setup --generate-auto-start zsh)"
    '');

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration
      (mkOrder 200 ''
        eval (zellij setup --generate-auto-start fish | string collect)
      '');
  };
}

