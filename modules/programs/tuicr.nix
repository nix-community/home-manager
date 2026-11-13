{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tuicr;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.pedromiguelvc ];

  options.programs.tuicr = {
    enable = lib.mkEnableOption "tuicr, a tui for code review with vim keybindings";

    package = lib.mkPackageOption pkgs "tuicr" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        theme = "catppuccin-mocha";
        diff_view = "side-by-side";
        ignore_whitespace = false;
        appearance = "system";
        mouse = true;
        leader = ";";
        editor = "nvim";
        comment_vim = false;
        relative_line_numbers = false;
        comment_types = [
          {
            id = "issue";
            color = "red";
            definition = "must fix before merge";
          }
        ];
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/tuicr/config.toml`.
        For available settings see
        <https://github.com/agavra/tuicr/blob/main/docs/CONFIG.md>
      '';
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      example = lib.literalExpression ''
        {
          my-theme = ./my-theme.toml;
        }
      '';
      description = ''
        Local tuicr themes. Each attribute name is the theme name and each value
        is a path to a flat TOML theme file. Files are linked to
        {file}`$XDG_CONFIG_HOME/tuicr/themes/<name>.toml`. Select one with
        `settings.theme = "<name>"`.

        Bundled theme names take precedence over local files with the same name.
        For the list of palette keys and bundled themes, see
        <https://github.com/agavra/tuicr/blob/main/docs/CONFIG.md#themes>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile =
      lib.mapAttrs' (
        name: path: lib.nameValuePair "tuicr/themes/${name}.toml" { source = path; }
      ) cfg.themes
      // {
        "tuicr/config.toml" = lib.mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "tuicr-config" cfg.settings;
        };
      };
  };
}
