{
  qt = {
    enable = true;
    platformTheme.name = "kde6"; # Should trigger warning and convert to "kde"
  };

  test.asserts.warnings.expected = [
    ''
      The value "kde6" for `qt.platformTheme.name` is deprecated and will be
      removed in a future release. Please use "kde" instead.
    ''
  ];

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
