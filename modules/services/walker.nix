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
    mkMerge
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.walker;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.services.walker = {
    enable = mkEnableOption "walker";
    package = mkPackageOption pkgs "walker" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        app_launch_prefix = "";
        terminal_title_flag = "";
        locale = "";
        close_when_open = false;
        theme = "default";
        monitor = "";
        hotreload_theme = false;
        as_window = false;
        timeout = 0;
        disable_click_to_close = false;
        force_keyboard_focus = false;
      };
      description = ''
        Configuration settings for walker. All the available options can be found here:
        <https://github.com/abenz1267/walker/wiki/Basic-Configuration>
      '';
    };

    theme = mkOption {
      type =
        with types;
        nullOr (submodule {
          options = {
            name = mkOption {
              type = types.str;
              default = "nixos";
              description = "The theme name.";
            };

            layout = mkOption {
              inherit (tomlFormat) type;
              default = { };
              description = ''
                The layout of the theme.

                See <https://github.com/abenz1267/walker/wiki/Theming> for the full list of options.
              '';
            };

            style = mkOption {
              type = lines;
              default = "";
              description = "The styling of the theme, written in GTK CSS.";
            };
          };
        });
      default = null;
      description = "The custom theme used by walker. Setting this option overrides `settings.theme`.";
    };

    systemd.enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whatever to enable Walker's Systemd Unit.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.walker" pkgs lib.platforms.linux)
        {
          assertion = cfg.systemd.enable -> (cfg.package != null);
          message = "Can't set services.walker.package to null if services.walker.systemd.enable is set to true;";
        }
      ];

      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      xdg.configFile."walker/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "walker-config" cfg.settings;
      };
      systemd.user.services.walker = mkIf (cfg.systemd.enable && cfg.package != null) {
        Unit.Description = "Walker - Application Runner";
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart = "${lib.getExe cfg.package} --gapplication-service";
          Restart = "on-failure";
        };
      };
    }
    (mkIf (cfg.theme != null) {
      services.walker.settings.theme = cfg.theme.name;
      xdg.configFile = {
        "walker/themes/${cfg.theme.name}.toml".source =
          tomlFormat.generate "walker-theme-${cfg.theme.name}.toml" cfg.theme.layout;
        "walker/themes/${cfg.theme.name}.css".text = cfg.theme.style;
      };
    })
  ]);
}
