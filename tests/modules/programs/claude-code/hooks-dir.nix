{
  programs.claude-code = {
    enable = true;
    hooksDir = ./hooks;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/hooks/test-hook
    assertLinkExists home-files/.claude/hooks/test-hook
    assertFileContent \
      home-files/.claude/hooks/test-hook \
      ${./hooks/test-hook}
  '';
}
