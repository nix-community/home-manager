{
  # Test GTK4 theme CSS injection with both theme and custom CSS
  gtk = {
    enable = true;

    gtk4 = {
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
    # GTK4 CSS should exist and contain no theme import and only custom CSS
    assertFileExists home-files/.config/gtk-4.0/gtk.css
    assertFileContent home-files/.config/gtk-4.0/gtk.css ${./gtk4-no-theme-css-injection-expected.css}
  '';
}
