{
  qt = {
    enable = true;
    qt5ctSettings = {
      test_section.test_option = "test";
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/qt5ct/qt5ct.conf"
    assertPathNotExists "home-files/.config/qt6ct/qt6ct.conf"
  '';
}
