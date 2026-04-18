{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.programs.wlr-which-key;
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.programs.wlr-which-key = {
    enable = lib.mkEnableOption "wlr-which-key";

    package = lib.mkPackageOption pkgs "wlr-which-key" { };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          font= "Iosevka Term Nerd Font 10";
          border= "#bd6f3e";
          color =  "#ebdbb2";

          separator = " ➜ ";
          border_width = 2;
          corner_r = 15;
          padding = 15;
          rows_per_column = 5;
          column_padding = 25;

          anchor = "bottom-right";
          margin_right = 0;
          margin_bottom = 5;
          margin_left = 5;
          margin_top = 0;
        }
      '';
      description = ''
        Main wlr-which-key configuration written to config.yaml.

        See <https://github.com/MaxVerevkin/wlr-which-key#configuration>
        for Configuration Documentation.
      '';
    };

    inheritSettings = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether extra menus inherit top-level settings from settings.";
    };

    extraMenus = mkOption {
      type = types.attrsOf yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        apps.menu = [
          {
            key = "f";
            desc = "Firefox";
            cmd = "firefox";
          }
          {
            key = "v";
            desc = "Vesktop";
            cmd = "vesktop";
          }
          {
            key = "q";
            desc = "Qutebrowser";
            cmd = "qutebrowser";
          }
        ]
      '';
      description = "Additional named menus, each written to wlr-which-key/<name>.yaml.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      (mkIf (cfg.settings != { }) {
        "wlr-which-key/config.yaml".source = yamlFormat.generate "wlr-which-key-main" cfg.settings;
      })
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "wlr-which-key/${name}.yaml" {
          source = yamlFormat.generate "wlr-which-key-${name}" (
            lib.optionalAttrs cfg.inheritSettings cfg.settings // value
          );
        }
      ) cfg.extraMenus)
    ];
  };
}
