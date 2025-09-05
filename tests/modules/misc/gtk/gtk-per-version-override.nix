{
  gtk = {
    enable = true;
    # Global defaults
    font.name = "Global Font";
    theme.name = "Global-Theme";
    iconTheme.name = "Global-Icons";
    cursorTheme.name = "Global-Cursor";

    # Per-version overrides
    gtk2 = {
      font.name = "GTK2-Font";
      theme.name = "GTK2-Theme";
      extraConfig = "gtk-can-change-accels = 1";
    };

    gtk3 = {
      iconTheme.name = "GTK3-Icons";
      cursorTheme.name = "GTK3-Cursor";
      extraConfig = {
        gtk-recent-files-limit = 10;
      };
      extraCss = "window { border: 1px solid red; }";
    };

    gtk4 = {
      font.name = "GTK4-Font";
      extraConfig = {
        gtk-recent-files-limit = 20;
      };
      extraCss = "window { border: 2px solid blue; }";
    };
  };

  nmt.script = ''
    # GTK2 should use overridden font/theme, global icons/cursor
    assertFileExists home-files/.gtkrc-2.0
    assertFileContent home-files/.gtkrc-2.0 \
      ${./gtk-per-version-override-gtk2-expected.conf}

    # GTK3 should use global font/theme, overridden icons/cursor
    assertFileExists home-files/.config/gtk-3.0/settings.ini
    assertFileContent home-files/.config/gtk-3.0/settings.ini \
      ${./gtk-per-version-override-gtk3-expected.ini}
    assertFileExists home-files/.config/gtk-3.0/gtk.css
    assertFileContent home-files/.config/gtk-3.0/gtk.css \
      ${./gtk-per-version-override-gtk3-css-expected.css}

    # GTK4 should use overridden font, global theme/icons/cursor
    assertFileExists home-files/.config/gtk-4.0/settings.ini
    assertFileContent home-files/.config/gtk-4.0/settings.ini \
      ${./gtk-per-version-override-gtk4-expected.ini}
    assertFileExists home-files/.config/gtk-4.0/gtk.css
    assertFileContent home-files/.config/gtk-4.0/gtk.css \
      ${./gtk-per-version-override-gtk4-css-expected.css}
  '';
}
