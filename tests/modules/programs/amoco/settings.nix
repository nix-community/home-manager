{
  programs.amoco = {
    enable = true;
    config = ''
      print("No example config found!")
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/amoco/config
    assertFileContent home-files/.config/amoco/config \
      ${./config}
  '';
}
