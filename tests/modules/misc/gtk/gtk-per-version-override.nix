{
  # Test that per-version settings override global defaults
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
    assertFileRegex home-files/.gtkrc-2.0 'gtk-font-name = "GTK2-Font 11"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-theme-name = "GTK2-Theme"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-icon-theme-name = "Global-Icons"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-cursor-theme-name = "Global-Cursor"'
    assertFileRegex home-files/.gtkrc-2.0 'gtk-can-change-accels = 1'

    # GTK3 should use global font/theme, overridden icons/cursor
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-font-name=Global Font 11'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-theme-name=Global-Theme'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-icon-theme-name=GTK3-Icons'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-cursor-theme-name=GTK3-Cursor'
    assertFileRegex home-files/.config/gtk-3.0/settings.ini 'gtk-recent-files-limit=10'
    assertFileRegex home-files/.config/gtk-3.0/gtk.css 'window { border: 1px solid red; }'

    # GTK4 should use overridden font, global theme/icons/cursor
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-font-name=GTK4-Font 11'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-theme-name=Global-Theme'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-icon-theme-name=Global-Icons'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-cursor-theme-name=Global-Cursor'
    assertFileRegex home-files/.config/gtk-4.0/settings.ini 'gtk-recent-files-limit=20'
    assertFileRegex home-files/.config/gtk-4.0/gtk.css 'window { border: 2px solid blue; }'
  '';
}
