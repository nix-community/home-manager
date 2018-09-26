{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.gtk;
  cfg2 = config.gtk.gtk2;
  cfg3 = config.gtk.gtk3;

  dag = config.lib.dag;

  toGtk3Ini = generators.toINI {
    mkKeyValue = key: value:
      let
        value' =
          if isBool value then (if value then "true" else "false")
          else toString value;
      in
        "${key}=${value'}";
  };

  formatGtk2Option = n: v:
    let
      v' =
        if isBool v then (if v then "true" else "false")
        else if isString v then "\"${v}\""
        else toString v;
    in
      "${n} = ${v'}";

  toDconfIni = generators.toINI {
    mkKeyValue = key: value:
      let
        tweakVal = v:
          if isString v then "'${v}'"
          else toString v;
      in
        "${key}=${tweakVal value}";
  };

  fontType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExample "pkgs.dejavu_fonts";
        description = ''
          Package providing the font. This package will be installed
          to your profile. If <literal>null</literal> then the font
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "DejaVu Sans 8";
        description = ''
          The family name and size of the font within the package.
        '';
      };
    };
  };

  themeType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExample "pkgs.gnome3.gnome_themes_standard";
        description = ''
          Package providing the theme. This package will be installed
          to your profile. If <literal>null</literal> then the theme
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "Adwaita";
        description = "The name of the theme within the package.";
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    gtk = {
      enable = mkEnableOption "GTK 2/3 configuration";

      font = mkOption {
        type = types.nullOr fontType;
        default = null;
        description = ''
          The font to use in GTK+ 2/3 applications.
        '';
      };

      iconTheme = mkOption {
        type = types.nullOr themeType;
        default = null;
        description = "The icon theme to use.";
      };

      theme = mkOption {
        type = types.nullOr themeType;
        default = null;
        description = "The GTK+2/3 theme to use.";
      };

      gtk2 = mkOption {
        description = "Options specific to GTK+ 2";
        default = {};
        type = types.submodule {
          options = {
            extraConfig = mkOption {
              type = types.lines;
              default = "";
              example = "gtk-can-change-accels = 1";
              description = ''
                Extra configuration lines to add verbatim to
                <filename>~/.gtkrc-2.0</filename>.
              '';
            };
          };
        };
      };

      gtk3 = mkOption {
        description = "Options specific to GTK+ 3";
        default = {};
        type = types.submodule {
          options = {
            extraConfig = mkOption {
              type = types.attrs;
              default = {};
              example = { gtk-cursor-blink = false; gtk-recent-files-limit = 20; };
              description = ''
                Extra configuration options to add to
                <filename>~/.config/gtk-3.0/settings.ini</filename>.
              '';
            };

            extraCss = mkOption {
              type = types.lines;
              default = "";
              description = ''
                Extra configuration lines to add verbatim to
                <filename>~/.config/gtk-3.0/gtk.css</filename>.
              '';
            };
            waylandSupport = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Support GSettings provider (dconf) in addition
                to GtkSettings (ini file). Needed for Wayland.
                The following line is needed in system configuration:
                  services.dbus.packages = [ pkgs.gnome3.dconf ];
              '';
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (
    let
      ini =
        optionalAttrs (cfg.font != null)
          { gtk-font-name = cfg.font.name; }
        //
        optionalAttrs (cfg.theme != null)
          { gtk-theme-name = cfg.theme.name; }
        //
        optionalAttrs (cfg.iconTheme != null)
          { gtk-icon-theme-name = cfg.iconTheme.name; };

      dconfIni =
        optionalAttrs (cfg.font != null)
          { font-name = cfg.font.name; }
        //
        optionalAttrs (cfg.theme != null)
          { gtk-theme = cfg.theme.name; }
        //
        optionalAttrs (cfg.iconTheme != null)
          { icon-theme = cfg.iconTheme.name; };

      optionalPackage = opt:
        optional (opt != null && opt.package != null) opt.package;
    in
      {

        home.packages =
          optionalPackage cfg.font
          ++ optionalPackage cfg.theme
          ++ optionalPackage cfg.iconTheme;

        home.file.".gtkrc-2.0".text =
          concatStringsSep "\n" (
            mapAttrsToList formatGtk2Option ini
          ) + "\n" + cfg2.extraConfig;

        xdg.configFile."gtk-3.0/settings.ini".text =
          toGtk3Ini { Settings = ini // cfg3.extraConfig; };

        xdg.configFile."gtk-3.0/gtk.css".text = cfg3.extraCss;

        home.activation = optionalAttrs cfg3.waylandSupport {
          gtk3 = dag.entryAfter ["installPackages"] (
          let
            iniText = toDconfIni { "/" = dconfIni; };
            iniFile = pkgs.writeText "gtk3.ini" iniText;
            dconfPath = "/org/gnome/desktop/interface/";
          in
            ''
              if [[ -v DRY_RUN ]]; then
                echo ${pkgs.gnome3.dconf}/bin/dconf load ${dconfPath} "<" ${iniFile}
              else
                ${pkgs.gnome3.dconf}/bin/dconf load ${dconfPath} < ${iniFile}
              fi
            ''
          );
        };
      }
    );
}
