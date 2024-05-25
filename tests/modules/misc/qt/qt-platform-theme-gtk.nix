{
  config = {
    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };
    i18n.inputMethod.enabled = "fcitx5";

    nmt.script = ''
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_QPA_PLATFORMTHEME="gtk2"'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_PLUGIN_PATH'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QML2_IMPORT_PATH'
    '';
  };
}
