{ config, lib, ... }:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    types
    ;

  cfg = config.gtk;
  cfg2 = config.gtk.gtk2;
  cfg3 = config.gtk.gtk3;
  cfg4 = config.gtk.gtk4;

  toIni = lib.generators.toINI {
    mkKeyValue =
      key: value:
      let
        value' = if lib.isBool value then lib.boolToString value else toString value;
      in
      "${lib.escape [ "=" ] key}=${value'}";
  };

  formatGtk2Option =
    n: v:
    let
      v' =
        if lib.isBool v then
          lib.boolToString v
        else if lib.isString v then
          ''"${v}"''
        else
          toString v;
    in
    "${lib.escape [ "=" ] n} = ${v'}";

  themeType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExpression "pkgs.gnome.gnome-themes-extra";
        description = ''
          Package providing the theme. This package will be installed
          to your profile. If `null` then the theme
          is assumed to already be available in your profile.

          For the theme to apply to GTK 4, this option is mandatory.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "Adwaita";
        description = "The name of the theme within the package.";
      };
    };
  };

  iconThemeType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExpression "pkgs.adwaita-icon-theme";
        description = ''
          Package providing the icon theme. This package will be installed
          to your profile. If `null` then the theme
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "Adwaita";
        description = "The name of the icon theme within the package.";
      };
    };
  };

  cursorThemeType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExpression "pkgs.vanilla-dmz";
        description = ''
          Package providing the cursor theme. This package will be installed
          to your profile. If `null` then the theme
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "Vanilla-DMZ";
        description = "The name of the cursor theme within the package.";
      };

      size = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 16;
        description = ''
          The size of the cursor.
        '';
      };
    };
  };

  # Helper function to generate the settings attribute set for a given version
  mkGtkSettings =
    {
      font,
      theme,
      iconTheme,
      cursorTheme,
    }:
    optionalAttrs (font != null) {
      gtk-font-name =
        let
          fontSize = if font.size != null then font.size else 11;
        in
        "${font.name} ${toString fontSize}";
    }
    // optionalAttrs (theme != null) { "gtk-theme-name" = theme.name; }
    // optionalAttrs (iconTheme != null) { "gtk-icon-theme-name" = iconTheme.name; }
    // optionalAttrs (cursorTheme != null) { "gtk-cursor-theme-name" = cursorTheme.name; }
    // optionalAttrs (cursorTheme != null && cursorTheme.size != null) {
      "gtk-cursor-theme-size" = cursorTheme.size;
    };

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  imports = [
    (lib.mkRemovedOptionModule [ "gtk" "gtk3" "waylandSupport" ] ''
      This options is not longer needed and can be removed.
    '')
  ];

  options.gtk = {
    enable = mkEnableOption "GTK theming and configuration";

    # Global settings that act as defaults for version-specific settings
    font = mkOption {
      type = types.nullOr lib.hm.types.fontType;
      default = null;
      description = "Default font for all GTK versions.";
    };

    theme = mkOption {
      type = types.nullOr themeType;
      default = null;
      description = "Default theme for all GTK versions.";
    };

    iconTheme = mkOption {
      type = types.nullOr iconThemeType;
      default = null;
      description = "Default icon theme for all GTK versions.";
    };

    cursorTheme = mkOption {
      type = types.nullOr cursorThemeType;
      default = null;
      description = "Default cursor theme for all GTK versions.";
    };

    # GTK2 options
    gtk2 = {
      enable = mkEnableOption "GTK 2 configuration" // {
        default = true;
      };
      font = mkOption {
        type = types.nullOr lib.hm.types.fontType;
        default = cfg.font;
        defaultText = literalExpression "config.gtk.font";
        description = "Font for GTK 2 applications.";
      };
      theme = mkOption {
        type = types.nullOr themeType;
        default = cfg.theme;
        defaultText = literalExpression "config.gtk.theme";
        description = "Theme for GTK 2 applications.";
      };
      iconTheme = mkOption {
        type = types.nullOr iconThemeType;
        default = cfg.iconTheme;
        defaultText = literalExpression "config.gtk.iconTheme";
        description = "Icon theme for GTK 2 applications.";
      };
      cursorTheme = mkOption {
        type = types.nullOr cursorThemeType;
        default = cfg.cursorTheme;
        defaultText = literalExpression "config.gtk.cursorTheme";
        description = "Cursor theme for GTK 2 applications.";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = "gtk-can-change-accels = 1";
        description = "Extra lines to add to {file}`~/.gtkrc-2.0`.";
      };
      configLocation = mkOption {
        type = types.path;
        default = "${config.home.homeDirectory}/.gtkrc-2.0";
        defaultText = literalExpression ''"''${config.home.homeDirectory}/.gtkrc-2.0"'';
        example = literalExpression ''"''${config.xdg.configHome}/gtk-2.0/gtkrc"'';
        description = "The location of the GTK 2 configuration file.";
      };
    };

    # GTK3 Options
    gtk3 = {
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
        type = types.nullOr themeType;
        default = cfg.theme;
        defaultText = literalExpression "config.gtk.theme";
        description = "Theme for GTK 3 applications.";
      };
      iconTheme = mkOption {
        type = types.nullOr iconThemeType;
        default = cfg.iconTheme;
        defaultText = literalExpression "config.gtk.iconTheme";
        description = "Icon theme for GTK 3 applications.";
      };
      cursorTheme = mkOption {
        type = types.nullOr cursorThemeType;
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

    # GTK4 Options
    gtk4 = {
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
        type = types.nullOr themeType;
        default = cfg.theme;
        defaultText = literalExpression "config.gtk.theme";
        description = "Theme for GTK 4 applications.";
      };
      iconTheme = mkOption {
        type = types.nullOr iconThemeType;
        default = cfg.iconTheme;
        defaultText = literalExpression "config.gtk.iconTheme";
        description = "Icon theme for GTK 4 applications.";
      };
      cursorTheme = mkOption {
        type = types.nullOr cursorThemeType;
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
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages =
          let
            collectPackages =
              cfgVersion:
              lib.filter (pkg: pkg != null) (
                optional (cfgVersion.enable && cfgVersion.theme != null) cfgVersion.theme.package
                ++ optional (cfgVersion.enable && cfgVersion.iconTheme != null) cfgVersion.iconTheme.package
                ++ optional (cfgVersion.enable && cfgVersion.cursorTheme != null) cfgVersion.cursorTheme.package
                ++ optional (cfgVersion.enable && cfgVersion.font != null) cfgVersion.font.package
              );
            allPackages = collectPackages cfg2 ++ collectPackages cfg3 ++ collectPackages cfg4;
          in
          lib.unique allPackages;

        # DConf settings are primarily for GNOME/GTK3/4 apps. We'll source them from gtk3 config.
        dconf.settings = mkIf cfg3.enable {
          "org/gnome/desktop/interface" =
            let
              settings = mkGtkSettings {
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

      # GTK2 Configuration
      (mkIf cfg2.enable {
        home.file.${cfg2.configLocation} = {
          text =
            let
              settings = mkGtkSettings {
                inherit (cfg2)
                  font
                  theme
                  iconTheme
                  cursorTheme
                  ;
              };
              settingsText = lib.concatMapStrings (n: "${formatGtk2Option n settings.${n}}\n") (
                lib.attrNames settings
              );
            in
            ''
              ${settingsText}${cfg2.extraConfig}
            '';
        };
        home.sessionVariables.GTK2_RC_FILES = cfg2.configLocation;
      })

      # GTK3 Configuration
      (mkIf cfg3.enable {
        xdg.configFile = {
          "gtk-3.0/settings.ini" = {
            text = toIni {
              Settings =
                mkGtkSettings {
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
      })

      # GTK4 Configuration
      (mkIf cfg4.enable {
        xdg.configFile = {
          "gtk-4.0/settings.ini" = {
            text = toIni {
              Settings =
                mkGtkSettings {
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
      })
    ]
  );
}
