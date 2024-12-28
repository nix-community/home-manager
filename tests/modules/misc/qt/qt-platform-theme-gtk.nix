{
  imports = [ ../../i18n/input-method/fcitx5-stubs.nix ];

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  i18n.inputMethod.enabled = "fcitx5";

  nixpkgs.overlays = [
    (final: prev: {
      libsForQt5 = prev.libsForQt5.overrideScope (qt5final: qt5prev: {
        qtstyleplugins = prev.mkStubPackage { outPath = null; };
      });

      qt6Packages = prev.qt6Packages.overrideScope (qt6final: qt6prev: {
        qt6gtk2 = prev.mkStubPackage { outPath = null; };
      });
    })
  ];

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_QPA_PLATFORMTHEME="gtk2"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_PLUGIN_PATH'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QML2_IMPORT_PATH'
  '';
}
