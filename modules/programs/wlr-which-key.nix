{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.wlr-which-key;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.maintainers; [
    LilleAila
    mightyiam
    minijackson
  ];

  options.programs.wlr-which-key = {
    enable = lib.mkEnableOption "wlr-which-key";

    package = lib.mkPackageOption pkgs "wlr-which-key" { nullable = true; };

    commonSettings = lib.mkOption {
      type = lib.types.submodule { freeformType = yamlFormat.type; };

      default = { };
      example = {
        anchor = "center";
        background = "#282828d0";
        border = "#8ec07c";
        color = "#fbf1c7";
      };

      description = ''
        Settings to be applied to every configuration under the `configs` option.
      '';
    };

    configs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = yamlFormat.type;

          options.menu = lib.mkOption {
            description = "The various menus to display";
            type = lib.types.attrs;
          };

          config = cfg.commonSettings;
        }
      );

      default = { };
      example.config = {
        anchor = "center";
        menu = {
          p = {
            desc = "Power";
            submenu = {
              o = {
                cmd = "poweroff";
                desc = "Off";
              };
              r = {
                cmd = "reboot";
                desc = "Reboot";
              };
              s = {
                cmd = "systemctl suspend";
                desc = "Sleep";
              };
            };
          };
        };
      };

      description = ''
        Various configurations for wlr-which-key.

        Each configuration `configs.''${name}` is installed into
        `~/.config/wlr-which-key/''${name}.yaml`.

        This enables you to run: `wlr-which-key ''${name}`.

        To set the default menu, use `programs.wlr-which-key.configs.config`.

        For more information on available options, see:
        <https://github.com/MaxVerevkin/wlr-which-key/>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = lib.mapAttrs' (
      name: value:
      lib.nameValuePair "wlr-which-key/${name}.yaml" {
        source = yamlFormat.generate "wlr-which-key-${name}.yaml" value;
      }
    ) cfg.configs;
  };
}
