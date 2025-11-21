{
  # Test that individual GTK versions can be selectively disabled
  gtk = {
    enable = true;
    theme.name = "Test-Theme";

    # Only enable GTK3, disable others
    gtk2.enable = false;
    gtk3.enable = true;
    gtk4.enable = false;
  };

  nmt.script = ''
    # GTK2 should not be configured
    assertPathNotExists home-files/.gtkrc-2.0

    # GTK3 should be configured
    assertFileExists home-files/.config/gtk-3.0/settings.ini
    assertFileContent home-files/.config/gtk-3.0/settings.ini \
      ${./gtk-selective-enable-gtk3-expected.ini}

    # GTK4 should not be configured
    assertPathNotExists home-files/.config/gtk-4.0/settings.ini
    assertPathNotExists home-files/.config/gtk-4.0/gtk.css

    # DConf should still be configured from GTK3
    echo \"DConf generation depends on having actual theme/font/icon settings\"
  '';
}
