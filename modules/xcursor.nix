{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xcursor;

  cursorType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        example = literalExample "pkgs.vanilla-dmz";
        description = "Package providing the cursor theme.";
      };

      name = mkOption {
        type = types.str;
        example = "Vanilla-DMZ";
        description = "The cursor name within the package.";
      };

      size = mkOption {
        type = types.int;
        default = 32;
        example = 64;
        description = "The cursor size.";
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.league ];

  options = {
    xcursor = mkOption {
      type = types.nullOr cursorType;
      default = null;
      description = ''
        The X cursor theme to use.
      '';
    };
  };

  config = mkIf (cfg != null) {

    home.packages = [cfg.package];

    xsession.initExtra = ''
      ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${cfg.package}/share/icons/${cfg.name}/cursors/X_cursor ${toString cfg.size}
    '';

    xresources.properties = {
      "Xcursor.theme" = cfg.name;
      "Xcursor.size"  = cfg.size;
    };

    gtk.gtk2.extraConfig = ''
      gtk-cursor-theme-name="${cfg.name}"
      gtk-cursor-theme-size=${toString cfg.size}
    '';

    gtk.gtk3.extraConfig = {
      "gtk-cursor-theme-name" = cfg.name;
      "gtk-cursor-theme-size" = cfg.size;
    };


  };
}
