{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.programs.wallust;
  tomlFormat = pkgs.formats.toml { };

  templateModule = { ... }: {
    options = {
      template = mkOption {
        type = types.path;

        example = ''
          fetchurl {
            url = "https://raw.githubusercontent.com/dylanaraps/pywal/master/pywal/templates/colors.json";
            hash = "";
          };
        '';
        description = "The template source file";
      };

      target = mkOption {
        type = types.str;

        example = "$XDG_CACHE_HOME/wal/colors.json";
        description = "The destination of the processed template";
      };
    };
  };

in {
  options.programs.wallust = {
    enable = mkOption {
      type = types.bool;
      default = false;

      example = true;
      description = "Whether to enable wallust.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };

      example = ''
        {
          backend = "fastresize";
          color_space = "labfast";
        }
      '';
      description = ''
        Wallust configuration file.

        Written to {file}`$XDG_CONFIG_HOME/wallust/wallust.toml`
        An example configuration can be found at <https://codeberg.org/explosion-mental/wallust/src/tag/2.10.0/wallust.toml>
      '';
    };

    templates = mkOption {
      type = with types; listOf (submodule templateModule);
      default = [ ];

      example = literalExpression ''
        [
          {
            template = ../../../dotfiles/pywal/colors.json;
            target = "''${config.xdg.cacheHome}/wal/colors.json";
          }
        ];
      '';
      description =
        "A list of templates and their target destinations that wallust is supposed to process.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.wallust ];

    xdg.configFile."wallust/wallust.toml" = let
      defaultCfg = {
        backend = "fastresize";
        color_space = "labfast";
        threshold = 20;
        filter = "dark16";
      };
      mergedCfg = defaultCfg // cfg.settings // { entry = cfg.templates; };

    in { source = tomlFormat.generate "wallust.toml" mergedCfg; };
  };

  meta.maintainers = [ hm.maintainers.temp ]; # TODO
}
