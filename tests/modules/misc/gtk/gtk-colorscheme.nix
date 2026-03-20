{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme.name = "Adwaita";
    iconTheme.name = "Adwaita";

    # Global dark colorScheme
    colorScheme = "dark";

    # GTK3 overrides to light
    gtk3.colorScheme = "light";
  };

  nmt.script = ''
    # GTK3's settings should be untouched
    assertFileExists home-files/.config/gtk-3.0/settings.ini
    assertFileNotRegex home-files/.config/gtk-3.0/settings.ini \
      'gtk-application-prefer-dark-theme'

    # GTK4 should inherit global dark colorScheme
    assertFileExists home-files/.config/gtk-4.0/settings.ini
    assertFileContains home-files/.config/gtk-4.0/settings.ini \
      'gtk-application-prefer-dark-theme=true'
    assertFileContains home-files/.config/gtk-4.0/settings.ini \
      'gtk-interface-color-scheme=2'

    echo "ColorScheme test completed successfully"
  '';
}
