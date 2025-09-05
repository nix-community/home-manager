{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.gtk;
  cfg2 = config.gtk.gtk2;
  cfg3 = config.gtk.gtk3;
  cfg4 = config.gtk.gtk4;

  gtkLib = import ./gtk/lib.nix { inherit lib; };

  themeType = gtkLib.mkThemeType {
    typeName = "theme";
    packageExample = "pkgs.gnome.gnome-themes-extra";
  };

  iconThemeType = gtkLib.mkThemeType {
    typeName = "icon theme";
    packageExample = "pkgs.adwaita-icon-theme";
  };

  cursorThemeType = gtkLib.mkThemeType {
    typeName = "cursor theme";
    hasSize = true;
    packageExample = "pkgs.vanilla-dmz";
    nameExample = "Vanilla-DMZ";
  };

in

{
  meta.maintainers = with lib.maintainers; [
    khaneliman
    rycee
  ];

  imports = [
    ./gtk/gtk2.nix
    ./gtk/gtk3.nix
    ./gtk/gtk4.nix
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
  };

  config = mkIf cfg.enable {
    # Collect packages from all GTK versions
    home.packages = gtkLib.collectGtkPackages [
      cfg2
      cfg3
      cfg4
    ];
  };
}
