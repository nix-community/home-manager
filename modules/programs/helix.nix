{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.helix;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.Philipp-M ];

  options.programs.helix = {
    enable = mkEnableOption "helix text editor";

    package = mkOption {
      type = types.package;
      default = pkgs.helix;
      defaultText = literalExpression "pkgs.helix";
      description = "The package to use for helix.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "base16";
          lsp.display-messages = true;
          keys.normal = {
            space.space = "file_picker";
            space.w = ":w";
            space.q = ":q";
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/helix/config.toml</filename>.
        </para><para>
        See <link xlink:href="https://docs.helix-editor.com/configuration.html" />
        for the full list of options.
      '';
    };

    languages = mkOption {
      type = types.listOf tomlFormat.type;
      default = [ ];
      example = [{
        name = "rust";
        auto-format = false;
      }];
      description = ''
        Language specific configuration at
        <filename>$XDG_CONFIG_HOME/helix/languages.toml</filename>.
        </para><para>
        See <link xlink:href="https://docs.helix-editor.com/languages.html" />
        for more information.
      '';
    };

    grammars = mkOption {
      type = types.listOf tomlFormat.type;
      default = [ ];
      example = [{
        name = "lalrpop";
        source = {
          git = "https://github.com/traxys/tree-sitter-lalrpop";
          rev = "7744b56f03ac1e5643fad23c9dd90837fe97291e";
        };
      }];
      description = ''
        Language specific tree-sitter grammars at
        <filename>$XDG_CONFIG_HOME/helix/languages.toml</filename>.
        </para><para>
        See <link xlink:href="https://docs.helix-editor.com/languages.html#tree-sitter-grammar-configuration" />
        for more information.
      '';
    };

    use-grammars = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          only = [ "rust" "c" "cpp" ];
        }
      '';
      description = ''
        Controls which grammars are fetched and built when using
        <literal>hx --grammar fetch</literal> and
        <literal>hx --grammar build</literal>.
        </para><para>
        See <link xlink:href="https://docs.helix-editor.com/languages.html#choosing-grammars" />
        for more information.
      '';
    };

    themes = mkOption {
      type = types.attrsOf tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          base16 = let
            transparent = "none";
            gray = "#665c54";
            dark-gray = "#3c3836";
            white = "#fbf1c7";
            black = "#282828";
            red = "#fb4934";
            green = "#b8bb26";
            yellow = "#fabd2f";
            orange = "#fe8019";
            blue = "#83a598";
            magenta = "#d3869b";
            cyan = "#8ec07c";
          in {
            "ui.menu" = transparent;
            "ui.menu.selected" = { modifiers = [ "reversed" ]; };
            "ui.linenr" = { fg = gray; bg = dark-gray; };
            "ui.popup" = { modifiers = [ "reversed" ]; };
            "ui.linenr.selected" = { fg = white; bg = black; modifiers = [ "bold" ]; };
            "ui.selection" = { fg = black; bg = blue; };
            "ui.selection.primary" = { modifiers = [ "reversed" ]; };
            "comment" = { fg = gray; };
            "ui.statusline" = { fg = white; bg = dark-gray; };
            "ui.statusline.inactive" = { fg = dark-gray; bg = white; };
            "ui.help" = { fg = dark-gray; bg = white; };
            "ui.cursor" = { modifiers = [ "reversed" ]; };
            "variable" = red;
            "variable.builtin" = orange;
            "constant.numeric" = orange;
            "constant" = orange;
            "attributes" = yellow;
            "type" = yellow;
            "ui.cursor.match" = { fg = yellow; modifiers = [ "underlined" ]; };
            "string" = green;
            "variable.other.member" = red;
            "constant.character.escape" = cyan;
            "function" = blue;
            "constructor" = blue;
            "special" = blue;
            "keyword" = magenta;
            "label" = magenta;
            "namespace" = blue;
            "diff.plus" = green;
            "diff.delta" = yellow;
            "diff.minus" = red;
            "diagnostic" = { modifiers = [ "underlined" ]; };
            "ui.gutter" = { bg = black; };
            "info" = blue;
            "hint" = dark-gray;
            "debug" = dark-gray;
            "warning" = yellow;
            "error" = red;
          };
        }
      '';
      description = ''
        Each theme is written to
        <filename>$XDG_CONFIG_HOME/helix/themes/theme-name.toml</filename>.
        Where the name of each attribute is the theme-name (in the example "base16").
        </para><para>
        See <link xlink:href="https://docs.helix-editor.com/themes.html" />
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = let
      settings = {
        "helix/config.toml" = mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "helix-config" cfg.settings;
        };
        "helix/languages.toml" = mkIf (cfg.languages != [ ] || cfg.grammars
          != [ ] || cfg.use-grammars != { }) {
            source =
              # NB: helix requires that `use-grammars` be the first key in languages.toml if present
              # pkgs.formats.toml relies on piping generated json through
              # [remarshal](https://github.com/remarshal-project/remarshal),
              # so we have to concatenate in order to preserve this ordering
              let
                preface = tomlFormat.generate "helix-config" {
                  inherit (cfg) use-grammars;
                };
                body = tomlFormat.generate "helix-config" {
                  language = cfg.languages;
                  grammar = cfg.grammars;
                };
              in if cfg.use-grammars == { } then
                body
              else
                pkgs.concatTextFile {
                  name = "helix-config";
                  files = [ preface body ];
                };
          };
      };

      themes = (mapAttrs' (n: v:
        nameValuePair "helix/themes/${n}.toml" {
          source = tomlFormat.generate "helix-theme-${n}" v;
        }) cfg.themes);
    in settings // themes;
  };
}
