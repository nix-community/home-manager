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
    assertFileContent home-files/.config/gtk-4.0/gtk.css ${./gtk4-theme-css-injection-expected.css}
  '';
}
