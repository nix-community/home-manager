{
  programs.claude-code.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.claude
  '';
}
