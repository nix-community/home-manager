{
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
  };

  test.asserts.warnings.expected = [
    "The value `gtk` for option `qt.platformTheme.name` is deprecated. Use `gtk2` to keep the legacy qtstyleplugins or `gtk3` to use the modern native Qt GTK3 plugin."
  ];

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_QPA_PLATFORMTHEME="gtk3"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_PLUGIN_PATH'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QML2_IMPORT_PATH'
  '';
}
