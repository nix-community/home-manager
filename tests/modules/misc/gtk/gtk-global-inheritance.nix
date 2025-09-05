{ pkgs, ... }:
{
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
    assertFileContent home-files/.gtkrc-2.0 \
      ${./gtk-global-inheritance-gtk2-expected.conf}

    # Check GTK3 inherits global settings
    assertFileExists home-files/.config/gtk-3.0/settings.ini
    assertFileContent home-files/.config/gtk-3.0/settings.ini \
      ${./gtk-global-inheritance-gtk3-expected.ini}

    # Check GTK4 inherits global settings
    assertFileExists home-files/.config/gtk-4.0/settings.ini
    assertFileContent home-files/.config/gtk-4.0/settings.ini \
      ${./gtk-global-inheritance-gtk4-expected.ini}

    # Check GTK4 CSS with theme import
    assertFileExists home-files/.config/gtk-4.0/gtk.css
    assertFileContent home-files/.config/gtk-4.0/gtk.css ${./gtk-global-inheritance-gtk4-css-expected.css}
  '';
}
