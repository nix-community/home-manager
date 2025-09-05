{ config, lib, ... }:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.gtk;
  cfg4 = config.gtk.gtk4;

  gtkLib = import ./lib.nix { inherit lib; };

  toIni = lib.generators.toINI {
    mkKeyValue =
      key: value:
      let
        value' = if lib.isBool value then lib.boolToString value else toString value;
      in
      "${lib.escape [ "=" ] key}=${value'}";
  };

in

{
  options.gtk.gtk4 = {
    enable = mkEnableOption "GTK 4 configuration" // {
      default = true;
    };

    font = mkOption {
      type = types.nullOr lib.hm.types.fontType;
      default = cfg.font;
      defaultText = literalExpression "config.gtk.font";
      description = "Font for GTK 4 applications.";
    };

    theme = mkOption {
      type = types.nullOr (
        gtkLib.mkThemeType {
          typeName = "theme";
          packageExample = "pkgs.gnome.gnome-themes-extra";
        }
      );
      default = cfg.theme;
      defaultText = literalExpression "config.gtk.theme";
      description = "Theme for GTK 4 applications.";
    };

    iconTheme = mkOption {
      type = types.nullOr (
        gtkLib.mkThemeType {
          typeName = "icon theme";
          packageExample = "pkgs.adwaita-icon-theme";
        }
      );
      default = cfg.iconTheme;
      defaultText = literalExpression "config.gtk.iconTheme";
      description = "Icon theme for GTK 4 applications.";
    };

    cursorTheme = mkOption {
      type = types.nullOr (
        gtkLib.mkThemeType {
          typeName = "cursor theme";
          hasSize = true;
          packageExample = "pkgs.vanilla-dmz";
          nameExample = "Vanilla-DMZ";
        }
      );
      default = cfg.cursorTheme;
      defaultText = literalExpression "config.gtk.cursorTheme";
      description = "Cursor theme for GTK 4 applications.";
    };

    extraConfig = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          bool
          int
          str
        ]);
      default = { };
      example = {
        gtk-cursor-blink = false;
        gtk-recent-files-limit = 20;
      };
      description = "Extra settings for {file}`$XDG_CONFIG_HOME/gtk-4.0/settings.ini`.";
    };

    extraCss = mkOption {
      type = types.lines;
      default = "";
      description = "Extra CSS for {file}`$XDG_CONFIG_HOME/gtk-4.0/gtk.css`.";
    };
  };

  config = mkIf (cfg.enable && cfg4.enable) {
    xdg.configFile = {
      "gtk-4.0/settings.ini" = {
        text = toIni {
          Settings =
            gtkLib.mkGtkSettings {
              inherit (cfg4)
                font
                theme
                iconTheme
                cursorTheme
                ;
            }
            // cfg4.extraConfig;
        };
      };
      "gtk-4.0/gtk.css" =
        mkIf (cfg4.extraCss != "" || (cfg4.theme != null && cfg4.theme.package != null))
          {
            text =
              lib.optionalString (cfg4.theme != null && cfg4.theme.package != null) ''
                /**
                 * GTK 4 reads the theme configured by gtk-theme-name, but ignores it.
                 * It does however respect user CSS, so import the theme from here.
                **/
                @import url("file://${cfg4.theme.package}/share/themes/${cfg4.theme.name}/gtk-4.0/gtk.css");
              ''
              + cfg4.extraCss;
          };
    };
  };
}
