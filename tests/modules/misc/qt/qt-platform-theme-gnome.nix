{
  config = {
    qt = {
      enable = true;
      # Check if still backwards compatible
      platformTheme = "gnome";
      style.name = "adwaita";
    };

    test.stubs.qgnomeplatform = { };

    nmt.script = ''
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_QPA_PLATFORMTHEME="gnome"'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_STYLE_OVERRIDE="adwaita"'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_PLUGIN_PATH'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QML2_IMPORT_PATH'
    '';
    test.asserts.warnings.expected = [
      "The option `qt.platformTheme` has been renamed to `qt.platformTheme.name`."
      "The value `gnome` for option `qt.platformTheme` is deprecated. Use `adwaita` instead."
    ];
  };
}
