{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.gtk;
  cfg2 = config.gtk.gtk2;
  cfg3 = config.gtk.gtk3;

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

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    gtk = {
      enable = mkEnableOption "GTK 2/3 configuration";

      fontName = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "DejaVu Sans 8";
        description = ''
          The font to use in GTK+ 2/3 applications.
        '';
      };

      themeName = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Vertex-Dark";
        description = "The name of the GTK+2/3 theme to use.";
      };

      iconThemeName = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Tango";
        description = "The name of the icon theme to use.";
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
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (
    let
      ini =
        optionalAttrs (cfg.fontName != null)
          { gtk-font-name = cfg.fontName; }
        //
        optionalAttrs (cfg.themeName != null)
          { gtk-theme-name = cfg.themeName; }
        //
        optionalAttrs (cfg.iconThemeName != null)
          { gtk-icon-theme-name = cfg.iconThemeName; };
    in
      {
        home.file.".gtkrc-2.0".text =
          concatStringsSep "\n" (
            mapAttrsToList formatGtk2Option ini
          ) + "\n" + cfg2.extraConfig;

        xdg.configFile."gtk-3.0/settings.ini".text =
          toGtk3Ini { Settings = ini // cfg3.extraConfig; };

        xdg.configFile."gtk-3.0/gtk.css".text = cfg3.extraCss;
      }
    );
}
