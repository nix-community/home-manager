{
  programs.cursor-agent = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.cursor
  '';
}
