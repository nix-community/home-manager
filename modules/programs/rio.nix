{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.rio;

  settingsFormat = pkgs.formats.toml { };
in
{
  options.programs.rio = {
    enable = lib.mkEnableOption null // {
      description = ''
        Enable Rio, a terminal built to run everywhere, as a native desktop applications by
        Rust/WebGPU or even in the browsers powered by WebAssembly/WebGPU.
      '';
    };

    package = lib.mkPackageOption pkgs "rio" { nullable = true; };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/rio/config.toml`. See
        <https://raphamorim.io/rio/docs/#configuration-file> for options.
      '';
    };

    themes = lib.mkOption {
      type = with lib.types; attrsOf (either settingsFormat.type path);
      default = { };
      description = ''
        Theme files written to {file}`$XDG_CONFIG_HOME/rio/themes/`. See
        <https://rioterm.com/docs/config#building-your-own-theme> for
        supported values.
      '';
      example = lib.literalExpression ''
        {
          foobar.colors = {
            background = "#282a36";
            green = "#50fa7b";
            dim-green = "#06572f";
          };
        }
      '';
    };
  };
  meta.maintainers = [ lib.maintainers.otavio ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      }

      # Only manage configuration if not empty
      (lib.mkIf (cfg.settings != { }) {
        xdg.configFile."rio/config.toml".source =
          if lib.isPath cfg.settings then cfg.settings else settingsFormat.generate "rio.toml" cfg.settings;
      })

      (lib.mkIf (cfg.themes != { }) {
        xdg.configFile = lib.mapAttrs' (
          name: value:
          lib.nameValuePair "rio/themes/${name}.toml" {
            source =
              if builtins.isPath value then value else settingsFormat.generate "rio-theme-${name}.toml" value;
          }
        ) cfg.themes;
      })
    ]
  );
}
