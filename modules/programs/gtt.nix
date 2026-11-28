{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.gtt;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.richardsouzza ];

  options.programs.gtt = {
    enable = lib.mkEnableOption "gtt, Google Translate TUI";

    package = lib.mkPackageOption pkgs "gtt" { nullable = true; };

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          destination = {
            border_color = "red";
            language = {
              apertium = "English";
              bing = "English";
              deepl = "English";
              deeplx = "English";
              google = "English";
              libre = "English";
              reverso = "English";
            };
          };
          hide_below = false;
          osc52 = false;
          source = {
            border_color = "blue";
            language = {
              apertium = "Portuguese";
              bing = "Portuguese (Brazil)";
              deepl = "Portuguese";
              deeplx = "Portuguese";
              google = "Portuguese (Portugal, Brazil)";
              libre = "Portuguese";
              reverso = "Portuguese";
            };
          };
          theme = "gruvbox";
          translator = "Google";
          transparent = false;
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/gtt/gtt.yaml`

        The file is read-only, so changes made inside gtt
        (translator, languages, theme) are not saved and the
        declared settings always apply.

        See <https://github.com/eeeXun/gtt/blob/75f8679186eac64a957160352fe3b529ac556a9e/config.go#L39-L62> for documentation.
      '';
    };

    servers = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          api_key = {
            deepl = {
              file = "$HOME/secrets/deepl.txt";
            };
            deeplx = {
              file = "$HOME/secrets/deeplx.txt";
            };
            libre = {
              file = "$HOME/secrets/libre.txt";
            };
          };
          host = {
            deeplx = "127.0.0.1:1188";
            libre = "127.0.0.1:5000";
          };
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/gtt/server.yaml`

        Prefer `file` over `value` for API keys, since values set here end
        up in the world-readable Nix store.

        See <https://github.com/eeeXun/gtt#%EF%B8%8F-note-for-deepl> for documentation.
      '';
    };

    keymaps = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          clear = "C-q";
          copy_destination = "C-r";
          copy_selected = "C-y";
          copy_source = "C-g";
          exit = "C-c";
          stop_tts = "C-x";
          swap_language = "C-s";
          toggle_below = "C-\\";
          toggle_transparent = "C-t";
          translate = "C-j";
          tts_destination = "C-p";
          tts_source = "C-o";
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/gtt/keymap.yaml`

        See <https://github.com/eeeXun/gtt?tab=readme-ov-file#key-map> for documentation.
      '';
    };

    themes = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          tokyonight = {
            bg = "0x1A1B26";
            fg = "0xC0CAF5";
            gray = "0x414868";
            red = "0xF7768E";
            green = "0x9ECE6A";
            yellow = "0xE0AF68";
            blue = "0x7AA2F7";
            purple = "0xBB9AF7";
            cyan = "0x7DCFFF";
            orange = "0xFF9E64";
          };
          catppuccin = {
            bg = "0x24273A";
            fg = "0xCAD3F5";
            gray = "0x5B6078";
            red = "0xED8796";
            green = "0xA6DA95";
            yellow = "0xEED49F";
            blue = "0x8AADF4";
            purple = "0xF5BDE6";
            cyan = "0x8BD5CA";
            orange = "0xF5A97F";
          };
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/gtt/theme.yaml`

        See <https://github.com/eeeXun/gtt?tab=readme-ov-file#customize-theme> for documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "gtt/gtt.yaml" = lib.mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "gtt.yaml" cfg.settings;
      };

      "gtt/server.yaml" = lib.mkIf (cfg.servers != { }) {
        source = yamlFormat.generate "server.yaml" cfg.servers;
      };

      "gtt/keymap.yaml" = lib.mkIf (cfg.keymaps != { }) {
        source = yamlFormat.generate "keymap.yaml" cfg.keymaps;
      };

      "gtt/theme.yaml" = lib.mkIf (cfg.themes != { }) {
        source = yamlFormat.generate "theme.yaml" cfg.themes;
      };
    };
  };
}
