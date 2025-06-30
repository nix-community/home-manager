{ pkgs, ... }:
{
  # Test that global settings are inherited by all GTK versions
  gtk = {
    enable = true;
    font = {
      name = "Ubuntu";
      size = 12;
      package = pkgs.ubuntu_font_family;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };
  };

  nmt.script = ''
    # Check GTK2 inherits global settings
    assertFileExists home-files/.gtkrc-2.0
    assertFileRegex home-files/.gtkrc-2.0 'gtk-theme-name = "Adwaita-dark"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-font-name = "Ubuntu 12"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-icon-theme-name = "Adwaita"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-cursor-theme-name = "Adwaita"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-cursor-theme-size = 24'

    # Check GTK3 inherits global settings
    assertFileExists home-files/.config/gtk-3.0/settings.ini
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-theme-name=Adwaita-dark'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-font-name=Ubuntu 12'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-icon-theme-name=Adwaita'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-cursor-theme-name=Adwaita'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-cursor-theme-size=24'

    # Check GTK4 inherits global settings
    assertFileExists home-files/.config/gtk-4.0/settings.ini
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-theme-name=Adwaita-dark'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-font-name=Ubuntu 12'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-icon-theme-name=Adwaita'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-cursor-theme-name=Adwaita'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-cursor-theme-size=24'

    # Check GTK4 CSS with theme import
    assertFileExists home-files/.config/gtk-4.0/gtk.css
    assertFileRegex home-files/.config/gtk-4.0/gtk.css '@import url("file://.*/share/themes/Adwaita-dark/gtk-4.0/gtk.css")'

    # Check packages are installed
    # Package installation verified by home-manager
  '';
}
