{ config, lib, pkgs, ... }:

let

  cfg = config.programs.yambar;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ lib.maintainers.carpinchomug ];

  options.programs.yambar = {
    enable = lib.mkEnableOption "Yambar";

    package = lib.mkPackageOption pkgs "yambar" { };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        bar = {
          location = "top";
          height = 26;
          background = "00000066";

          right = [
            {
              clock.content = [
                {
                  string.text = "{time}";
                }
              ];
            }
          ];
        };
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/yambar/config.yml`.
        See {manpage}`yambar(5)` for options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.yambar" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."yambar/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yml" cfg.settings;
    };
  };
}
