{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.onagre;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.onagre = {
    enable = mkEnableOption "onagre";
    package = mkPackageOption pkgs "onagre" { nullable = true; };
    style = mkOption {
      type = types.lines;
      default = "";
      example = ''
        .onagre {
          --exit-unfocused: false;
          height: 250px;
          width: 400px;
          --font-family: "Iosevka,Iosevka Nerd Font";
          font-size: 18px;
          background: #151515;
          color: #414141;
          padding: 10px;

          .container {
            .rows {
              --height: fill-portion 6;
              .row-selected {
                color: #ffffff;
                --spacing: 3px;
              }
            }

            .scrollable {
              background: #151515;
              width: 0;
              .scroller {
                width: 0;
                color: #151515;
              }
            }
          }
        }
      '';
      description = ''
        Configuration file to be written to theme.scss for setting
        Onagre's theme. The documentation can be found here:
        <https://github.com/onagre-launcher/onagre/wiki/Theming>
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.onagre" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."onagre/theme.scss" = mkIf (cfg.style != "") { text = cfg.style; };
  };
}
