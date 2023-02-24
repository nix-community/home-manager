{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vivid;

  # Use JSON because the themes use colors in hexadecimal, hence some values can
  # start with a number, which YAML reads them as number instead of strings.
  jsonFormat = pkgs.formats.json { };

in {

  meta.maintainers = [ maintainers.marsam ];

  options.programs.vivid = {
    enable = mkEnableOption "vivid";

    package = mkPackageOption pkgs "vivid" { };

    theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "molokai";
      description = ''
        Color theme to enable.
        See <link xlink:href="https://github.com/sharkdp/vivid/tree/master/themes" />
        for the full list of bundled themes.
      '';
    };

    filetypes = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          core = {
            regular_file = [ "$fi" ];
            directory = [ "$di" ];
          };
          text = {
            special = [
              "README.md"
            ];
            licenses = [
              "COPYING"
              "LICENSE"
            ];
          };
        }
      '';
      description = ''
        Configuration for the filetype-database written to
        <filename>$XDG_CONFIG_HOME/vivid/filetypes.yml</filename>.
      '';
    };

    themes = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          mytheme = {
            colors = {
              blue = "0031a9";
            };
            core = {
              directory = {
                foreground = "blue";
                font-style = "bold";
              };
            };
          };
        }
      '';
      description = ''
        Custom color themes written to
        <filename>$XDG_CONFIG_HOME/vivid/themes/{theme}.yml</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = mkIf (cfg.theme != null) {
      LS_COLORS = "$(${cfg.package}/bin/vivid generate ${cfg.theme})";
    };

    xdg.configFile = {
      "vivid/filetypes.yml" = mkIf (cfg.filetypes != { }) {
        source = jsonFormat.generate "vivid-filetypes.yml" cfg.filetypes;
      };
    } // mapAttrs' (name: value:
      nameValuePair "vivid/themes/${name}.yml" {
        source = jsonFormat.generate "vivid-${name}-theme.yml" value;
      }) cfg.themes;
  };
}
