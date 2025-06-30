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
  cfg2 = config.gtk.gtk2;

  gtkLib = import ./lib.nix { inherit lib; };

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

in

{
  options.gtk.gtk2 = {
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
      type = types.nullOr (
        gtkLib.mkThemeType {
          typeName = "theme";
          packageExample = "pkgs.gnome.gnome-themes-extra";
        }
      );
      default = cfg.theme;
      defaultText = literalExpression "config.gtk.theme";
      description = "Theme for GTK 2 applications.";
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
      description = "Icon theme for GTK 2 applications.";
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

  config = mkIf (cfg.enable && cfg2.enable) {
    home.file.${cfg2.configLocation} = {
      text =
        let
          settings = gtkLib.mkGtkSettings {
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
  };
}
