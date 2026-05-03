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
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.wlr-which-key = {
    enable = lib.mkEnableOption "wlr-which-key, a keymap manager for wlroots-based compositors";

    package = lib.mkPackageOption pkgs "wlr-which-key" { nullable = true; };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          font = "JetBrainsMono Nerd Font 12";
          background = "#282828d0";
          color = "#fbf1c7";
          border = "#8ec07c";
          separator = " ➜ ";
          border_width = 2;
          corner_r = 10;
          padding = 15;
          rows_per_column = 5;
          column_padding = 25;
          anchor = "center";
          margin_right = 0;
          margin_bottom = 0;
          margin_left = 0;
          margin_top = 0;
          menu = [
            {
              key = "p";
              desc = "Power";
              submenu = [
                { key = "s"; desc = "Sleep"; cmd = "systemctl suspend"; }
                { key = "r"; desc = "Reboot"; cmd = "reboot"; }
                { key = "o"; desc = "Off"; cmd = "poweroff"; }
              ];
            }
          ];
        }
      '';
      description = ''
        Main wlr-which-key configuration written to
        {file}`$XDG_CONFIG_HOME/wlr-which-key/config.yaml`.

        See <https://github.com/MaxVerevkin/wlr-which-key#configuration>
        for the full list of options.
      '';
    };

    inheritSettings = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether all extra menus inherit top-level theming settings
        (e.g. font, background, border) from {option}`settings` by default.

        Can be overridden per menu via
        {option}`extraMenus.<name>.inheritSettings`.
      '';
    };

    extraMenus = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            inheritSettings = mkOption {
              type = types.bool;
              default = cfg.inheritSettings;
              example = true;
              description = ''
                Whether this menu inherits top-level theming settings from
                {option}`settings`. When enabled, the top-level settings are
                merged with this menu's {option}`settings`, with the latter
                taking precedence on conflicts.
              '';
            };

            settings = mkOption {
              inherit (yamlFormat) type;
              default = { };
              example = lib.literalExpression ''
                {
                  anchor = "bottom-left";
                  menu = [
                    { key = "f"; desc = "Firefox"; cmd = "firefox"; }
                    { key = "v"; desc = "Vesktop"; cmd = "vesktop"; }
                  ];
                }
              '';
              description = ''
                Configuration for this menu, written to
                {file}`$XDG_CONFIG_HOME/wlr-which-key/<name>.yaml`.
                Supports the same options as {option}`settings`, including
                theming and the {option}`menu` entry list.

                See <https://github.com/MaxVerevkin/wlr-which-key#configuration>
                for the full list of options.
              '';
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          apps = {
            inheritSettings = true;
            settings = {
              anchor = "bottom-left";
              menu = [
                { key = "f"; desc = "Firefox"; cmd = "firefox"; }
                { key = "v"; desc = "Vesktop"; cmd = "vesktop"; }
                { key = "q"; desc = "Qutebrowser"; cmd = "qutebrowser"; }
              ];
            };
          };
          power = {
            settings = {
              menu = [
                { key = "s"; desc = "Sleep"; cmd = "systemctl suspend"; }
                { key = "r"; desc = "Reboot"; cmd = "reboot"; }
                { key = "o"; desc = "Off"; cmd = "poweroff"; }
              ];
            };
          };
        }
      '';
      description = ''
        Additional named menu configurations, each written to
        {file}`$XDG_CONFIG_HOME/wlr-which-key/<name>.yaml`.
        These can be launched with `wlr-which-key -c <name>.yaml`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      (mkIf (cfg.settings != { }) {
        "wlr-which-key/config.yaml".source = yamlFormat.generate "wlr-which-key-config" cfg.settings;
      })
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "wlr-which-key/${name}.yaml" {
          source = yamlFormat.generate "wlr-which-key-${name}" (
            (lib.optionalAttrs value.inheritSettings cfg.settings) // value.settings
          );
        }
      ) cfg.extraMenus)
    ];
  };
}
