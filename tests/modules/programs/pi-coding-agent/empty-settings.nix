{
  programs.pi-coding-agent = {
    enable = true;
    settings = { };
  };
  nmt.script = ''
    assertPathNotExists home-files/.pi/agent/settings.json
  '';
}
