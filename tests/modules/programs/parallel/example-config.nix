{
  programs.parallel = {
    enable = true;
    will-cite = true;
  };

  nmt.script = ''
    assertFileExists home-files/.parallel/will-cite
  '';
}
