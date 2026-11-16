{
  programs.foot = {
    enable = true;
    package = null;

    settings.main.term = "xterm-256color";
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/foot

    assertFileContent \
      home-files/.config/foot/foot.ini \
      ${./null-package-expected.ini}
  '';
}
