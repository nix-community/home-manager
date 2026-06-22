{
  config,
  lib,
  options,
  ...
}:

{
  qt = {
    enable = true;
    useGtkTheme = true;
  };

  nixpkgs.overlays = [
    (_final: prev: {
      libsForQt5 = prev.libsForQt5.overrideScope (
        _qt5final: _qt5prev: {
          qtstyleplugins = config.lib.test.mkStubPackage {
            name = "qtstyleplugins";
            buildScript = ''
              mkdir -p $out/share
              touch $out/share/qtstyleplugins
            '';
          };
        }
      );

      qt6Packages = prev.qt6Packages.overrideScope (
        _qt6final: _qt6prev: {
          qt6gtk2 = config.lib.test.mkStubPackage {
            name = "qt6gtk2";
            buildScript = ''
              mkdir -p $out/share
              touch $out/share/qt6gtk2
            '';
          };
        }
      );
    })
  ];

  test.asserts.warnings.expected = [
    "The option `qt.useGtkTheme' defined in ${lib.showFiles options.qt.useGtkTheme.files} has been changed to `qt.platformTheme' that has a different type. Please read `qt.platformTheme' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_QPA_PLATFORMTHEME="gtk2"'
    assertFileExists home-path/share/qtstyleplugins
    assertFileExists home-path/share/qt6gtk2
  '';
}
