{ config, lib, pkgs, ... }:
let
  cfg = config.programs.ghostty;

  keyValueSettings = {
    listsAsDuplicateKeys = true;
    mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
  };
  keyValue = pkgs.formats.keyValue keyValueSettings;
in {
  meta.maintainers = [ lib.maintainers.HeitorAugustoLN ];

  options.programs.ghostty = {
    enable = lib.mkEnableOption "Ghostty";

    package = lib.mkPackageOption pkgs "ghostty" { };

    settings = lib.mkOption {
      inherit (keyValue) type;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "catppuccin-mocha";
          font-size = 10;
          keybind = [
            "ctrl+h=goto_split:left"
            "ctrl+l=goto_split:right"
          ];
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/ghostty/config`.

        See <https://ghostty.org/docs/config/reference> for more information.
      '';
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf keyValue.type;
      default = { };
      example = {
        catppuccin-mocha = {
          palette = [
            "0=#45475a"
            "1=#f38ba8"
            "2=#a6e3a1"
            "3=#f9e2af"
            "4=#89b4fa"
            "5=#f5c2e7"
            "6=#94e2d5"
            "7=#bac2de"
            "8=#585b70"
            "9=#f38ba8"
            "10=#a6e3a1"
            "11=#f9e2af"
            "12=#89b4fa"
            "13=#f5c2e7"
            "14=#94e2d5"
            "15=#a6adc8"
          ];
          background = "1e1e2e";
          foreground = "cdd6f4";
          cursor-color = "f5e0dc";
          selection-background = "353749";
          selection-foreground = "cdd6f4";
        };
      };
      description = ''
        Custom themes written to {file}`$XDG_CONFIG_HOME/ghostty/themes`.

        See <https://ghostty.org/docs/features/theme#authoring-a-custom-theme> for more information.
      '';
    };

    clearDefaultKeybinds = lib.mkEnableOption "" // {
      description = "Whether to clear default keybinds.";
    };

    installVimSyntax =
      lib.mkEnableOption "installation of Ghostty configuration syntax for Vim";

    installBatSyntax =
      lib.mkEnableOption "installation of Ghostty configuration syntax for bat"
      // {
        default = true;
      };

    enableBashIntegration = lib.mkEnableOption ''
      bash shell integration.

      This is ensures that shell integration works in more scenarios, such as switching shells within Ghostty.
      But it is not needed to have shell integration.
      See <https://ghostty.org/docs/features/shell-integration#manual-shell-integration-setup> for more information
    '';

    enableFishIntegration = lib.mkEnableOption ''
      fish shell integration.

      This is ensures that shell integration works in more scenarios, such as switching shells within Ghostty.
      But it is not needed to have shell integration.
      See <https://ghostty.org/docs/features/shell-integration#manual-shell-integration-setup> for more information
    '';

    enableZshIntegration = lib.mkEnableOption ''
      zsh shell integration.

      This is ensures that shell integration works in more scenarios, such as switching shells within Ghostty.
      But it is not needed to have shell integration.
      See <https://ghostty.org/docs/features/shell-integration#manual-shell-integration-setup> for more information
    '';
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ cfg.package ];

      programs.ghostty.settings = lib.mkIf cfg.clearDefaultKeybinds {
        keybind = lib.mkBefore [ "clear" ];
      };

      # MacOS also supports XDG configuration directory, so we use it for both
      # Linux and macOS to reduce complexity
      xdg.configFile = lib.mkMerge [
        {
          "ghostty/config" = lib.mkIf (cfg.settings != { }) {
            source = keyValue.generate "ghostty-config" cfg.settings;
            onChange = "${lib.getExe cfg.package} +validate-config";
          };
        }

        (lib.mkIf (cfg.themes != { }) (lib.mapAttrs' (name: value: {
          name = "ghostty/themes/${name}";
          value.source = keyValue.generate "ghostty-${name}-theme" value;
        }) cfg.themes))
      ];
    }

    (lib.mkIf cfg.installVimSyntax {
      programs.vim.plugins = [ cfg.package.vim ];
    })

    (lib.mkIf cfg.installBatSyntax {
      programs.bat = {
        syntaxes.ghostty = {
          src = cfg.package;
          file = "share/bat/syntaxes/ghostty.sublime-syntax";
        };
        config.map-syntax =
          [ "${config.xdg.configHome}/ghostty/config:Ghostty Config" ];
      };
    })

    (lib.mkIf cfg.enableBashIntegration {
      # Make order 101 to be placed exactly after bash completions, as Ghostty
      # documentation suggests sourcing the script as soon as possible
      programs.bash.initExtra = lib.mkOrder 101 ''
        if [[ -n "''${GHOSTTY_RESOURCES_DIR}" ]]; then
          builtin source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
        fi
      '';
    })

    (lib.mkIf cfg.enableFishIntegration {
      programs.fish.shellInit = ''
        if set -q GHOSTTY_RESOURCES_DIR
          source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
        end
      '';
    })

    (lib.mkIf cfg.enableZshIntegration {
      programs.zsh.initExtra = ''
        if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
          source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
        fi
      '';
    })
  ]);
}
