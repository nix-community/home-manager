{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.niriswitcher;

  settingsFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.vortriz ];

  options.programs.niriswitcher = {
    enable = lib.mkEnableOption "niriswitcher, an application switcher for niri";

    package = lib.mkPackageOption pkgs "niriswitcher" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.nullOr settingsFormat.type;
      default = null;
      example = lib.literalExpression ''
        {
          keys = {
            modifier = "Super";
            switch = {
              next = "Tab";
              prev = "Shift+Tab";
            };
          };
          center_on_focus = true;
          appearance = {
            system_theme = "dark";
            icon_size = 64;
          };
        }
      '';
      description = ''
        niriswitcher configuration.
        For available settings see <https://github.com/isaksamsten/niriswitcher/?tab=readme-ov-file#options>.
      '';
    };

    style = lib.mkOption {
      type = with lib.types; nullOr (either path lines);
      default = null;
      example = ''
        .application-name {
          opacity: 1;
          color: rgba(255, 255, 255, 0.6);
        }
        .application.selected .application-name {
          color: rgba(255, 255, 255, 1);
        }
      '';
      description = ''
        CSS style of the switcher.
        <https://github.com/isaksamsten/niriswitcher/?tab=readme-ov-file#themes>
        for the documentation.

        If the value is set to a path literal, then the path will be used as the CSS file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "niriswitcher is only available on Linux.";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "niriswitcher/config.toml" = lib.mkIf (cfg.settings != null) {
        source = settingsFormat.generate "config.toml" cfg.settings;
      };

      "niriswitcher/style.css" = lib.mkIf (cfg.style != null) {
        source =
          if builtins.isPath cfg.style || lib.isStorePath cfg.style then
            cfg.style
          else
            pkgs.writeText "niriswitcher/style.css" cfg.style;
      };
    };
  };
}
