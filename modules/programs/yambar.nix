{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.yambar;
  yamlFormat = pkgs.formats.yaml { };

in {
  options = {
    programs.yambar = {
      enable = mkEnableOption "Yambar";

      package = mkPackageOption pkgs "yambar" { };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
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
          Configuration written to
          <filename>$XDG_CONFIG_HOME/yambar/config.yml</filename>.
          See
          <citerefentry>
           <refentrytitle>yambar</refentrytitle>
           <manvolnum>5</manvolnum>
          </citerefentry>
          for options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.yambar" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."yambar/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yml" cfg.settings;
    };
  };

  meta.maintainers = [ maintainers.carpinchomug ];
}
