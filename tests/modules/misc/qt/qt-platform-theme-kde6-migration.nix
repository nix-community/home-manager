{
  qt = {
    enable = true;
    platformTheme.name = "kde6"; # Should trigger warning and convert to "kde"
  };

  nmt.script = ''
    # Verify that kde6 gets converted to kde in QT_QPA_PLATFORMTHEME
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_QPA_PLATFORMTHEME="kde"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_PLUGIN_PATH'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QML2_IMPORT_PATH'
  '';
}
