{
  programs.peon-ping = {
    enable = true;
    packs = [ ];
  };

  test.stubs.peon-ping = { };

  nmt.script = ''
    assertPathNotExists home-files/.claude/hooks/peon-ping/config.json
    assertPathNotExists home-files/.claude/settings.json
  '';
}
