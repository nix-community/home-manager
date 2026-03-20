{
  programs.am2rlauncher = {
    enable = true;
    config = ./config.xml;
  };

  nmt.script = ''
    assertFileExists home-files/.config/AM2RLauncher/config.xml
    assertFileContent home-files/.config/AM2RLauncher/config.xml \
      ${./config.xml}
  '';
}
