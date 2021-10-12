{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.pointerCursor;

  cursorType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        example = literalExpression "pkgs.vanilla-dmz";
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

      defaultCursor = mkOption {
        type = types.str;
        default = "left_ptr";
        example = "X_cursor";
        description = "The default cursor file to use within the package.";
      };
    };
  };

in {
  meta.maintainers = [ maintainers.league ];

  options = {
    xsession.pointerCursor = mkOption {
      type = types.nullOr cursorType;
      default = null;
      description = ''
        The X cursor theme and settings. The package
        <varname>xorg.xcursorthemes</varname> contains cursors named
        whiteglass, redglass, and handhelds. The package
        <varname>vanilla-dmz</varname> contains cursors named Vanilla-DMZ
        and Vanilla-DMZ-AA. Note: handhelds does not seem to work at
        custom sizes.
      '';
    };
  };

  config = mkIf (cfg != null) {
    assertions = [
      (hm.assertions.assertPlatform "xsession.pointerCursor" pkgs
        platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xsession.initExtra = ''
      ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${cfg.package}/share/icons/${cfg.name}/cursors/${cfg.defaultCursor} ${
        toString cfg.size
      }
    '';

    xresources.properties = {
      "Xcursor.theme" = cfg.name;
      "Xcursor.size" = cfg.size;
    };

    gtk.gtk2.extraConfig = ''
      gtk-cursor-theme-name="${cfg.name}"
      gtk-cursor-theme-size=${toString cfg.size}
    '';

    gtk.gtk3.extraConfig = {
      "gtk-cursor-theme-name" = cfg.name;
      "gtk-cursor-theme-size" = cfg.size;
    };

    # Set name in icons theme, for compatibility with AwesomeWM etc. See:
    # https://github.com/nix-community/home-manager/issues/2081
    # https://wiki.archlinux.org/title/Cursor_themes#XDG_specification
    home.file.".icons/default/index.theme".text = ''
      [icon theme]
      Name=Default
      Comment=Default Cursor Theme
      Inherits=${cfg.name}
    '';
  };
}
