{
  qt.enable = true;

  qt.kde.settings.powerdevilrc.AC.Display.DimDisplayIdleTimeoutSec = -1;

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_PLUGIN_PATH'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QML2_IMPORT_PATH'
    assertFileRegex activate \
      "kwriteconfig6 .*--file '/home/hm-user/.config/powerdevilrc' .*--key DimDisplayIdleTimeoutSec -- -1"
  '';
}
