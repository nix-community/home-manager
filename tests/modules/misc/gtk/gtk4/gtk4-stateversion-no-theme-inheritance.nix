{ pkgs, ... }:
{
  # Test that GTK4 theme does NOT inherit from global theme with stateVersion 26.05
  # This shows the new default behavior where gtk4.theme defaults to null
  home.stateVersion = "26.05";

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  nmt.script = ''
    # GTK4 settings should exist but WITHOUT theme (icon theme still inherits)
    assertFileExists home-files/.config/gtk-4.0/settings.ini
    assertFileContent home-files/.config/gtk-4.0/settings.ini \
      ${./gtk4-stateversion-no-theme-inheritance-expected.ini}

    # GTK4 CSS should NOT exist since no theme is configured
    assertPathNotExists home-files/.config/gtk-4.0/gtk.css
  '';
}
