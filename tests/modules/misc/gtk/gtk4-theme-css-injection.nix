{ pkgs, ... }:
{
  # Test GTK4 theme CSS injection with both theme and custom CSS
  gtk = {
    enable = true;

    gtk4 = {
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      extraCss = ''
        /* Custom user CSS */
        window {
          background-color: #2d2d2d;
        }

        button {
          border-radius: 8px;
        }
      '';
    };
  };

  nmt.script = ''
    # GTK4 CSS should exist and contain both theme import and custom CSS
    assertFileExists home-files/.config/gtk-4.0/gtk.css

    # Check for theme import comment and URL
    assertFileRegex home-files/.config/gtk-4.0/gtk.css '/\*\*'
    assertFileRegex home-files/.config/gtk-4.0/gtk.css 'GTK 4 reads the theme configured by gtk-theme-name, but ignores it'
    assertFileRegex home-files/.config/gtk-4.0/gtk.css '@import url("file://.*/share/themes/Adwaita-dark/gtk-4.0/gtk.css")'

    # Check for custom CSS
    assertFileRegex home-files/.config/gtk-4.0/gtk.css 'Custom user CSS'
    assertFileRegex home-files/.config/gtk-4.0/gtk.css 'background-color: #2d2d2d'
    assertFileRegex home-files/.config/gtk-4.0/gtk.css 'border-radius: 8px'

    # Verify the theme import comes before custom CSS
    css_content=$(cat home-files/.config/gtk-4.0/gtk.css)
    import_line=$(echo "$css_content" | grep -n "@import" | cut -d: -f1)
    custom_line=$(echo "$css_content" | grep -n "Custom user CSS" | cut -d: -f1)

    if [ "$import_line" -ge "$custom_line" ]; then
      echo "Theme import should come before custom CSS"
      exit 1
    fi
  '';
}
