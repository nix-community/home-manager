{
  config = {
    qt.enable = true;

    nmt.script = ''
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_PLUGIN_PATH'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QML2_IMPORT_PATH'
    '';
  };
}
