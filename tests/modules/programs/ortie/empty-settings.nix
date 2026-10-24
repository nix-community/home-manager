{
  programs.ortie = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ortie
  '';
}
