{
  programs.opencode = {
    enable = true;
    themes = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.config/opencode/themes
  '';
}
