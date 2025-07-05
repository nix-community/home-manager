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
  cfg3 = config.gtk.gtk3;

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
  options.gtk.gtk3 = {
    enable = mkEnableOption "GTK 3 configuration" // {
      default = true;
    };

    font = mkOption {
      type = types.nullOr lib.hm.types.fontType;
      default = cfg.font;
      defaultText = literalExpression "config.gtk.font";
      description = "Font for GTK 3 applications.";
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
      description = "Theme for GTK 3 applications.";
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
      description = "Icon theme for GTK 3 applications.";
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
      description = "Cursor theme for GTK 3 applications.";
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
      description = "Extra settings for {file}`$XDG_CONFIG_HOME/gtk-3.0/settings.ini`.";
    };

    extraCss = mkOption {
      type = types.lines;
      default = "";
      description = "Extra CSS for {file}`$XDG_CONFIG_HOME/gtk-3.0/gtk.css`.";
    };

    bookmarks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "file:///home/jane/Documents" ];
      description = "File browser bookmarks.";
    };
  };

  config = mkIf (cfg.enable && cfg3.enable) {
    xdg.configFile = {
      "gtk-3.0/settings.ini" = {
        text = toIni {
          Settings =
            gtkLib.mkGtkSettings {
              inherit (cfg3)
                font
                theme
                iconTheme
                cursorTheme
                ;
            }
            // cfg3.extraConfig;
        };
      };
      "gtk-3.0/gtk.css" = mkIf (cfg3.extraCss != "") {
        text = cfg3.extraCss;
      };
      "gtk-3.0/bookmarks" = mkIf (cfg3.bookmarks != [ ]) {
        text = lib.concatMapStrings (l: l + "\n") cfg3.bookmarks;
      };
    };

    # DConf settings are primarily for GNOME/GTK3/4 apps
    dconf.settings."org/gnome/desktop/interface" =
      let
        settings = gtkLib.mkGtkSettings {
          inherit (cfg3)
            font
            theme
            iconTheme
            cursorTheme
            ;
        };
      in
      lib.filterAttrs (_: v: v != null) {
        "font-name" = settings."gtk-font-name" or null;
        "gtk-theme" = settings."gtk-theme-name" or null;
        "icon-theme" = settings."gtk-icon-theme-name" or null;
        "cursor-theme" = settings."gtk-cursor-theme-name" or null;
        "cursor-size" = settings."gtk-cursor-theme-size" or null;
      };
  };
}
