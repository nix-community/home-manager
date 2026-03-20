{
  programs.opencode = {
    enable = true;
    settings = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.config/opencode/opencode.json
  '';
}
