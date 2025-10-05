{
  programs.claude-code = {
    enable = true;
    commandsDir = ./commands;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/commands/test-command.md
    assertLinkExists home-files/.claude/commands/test-command.md
    assertFileContent \
      home-files/.claude/commands/test-command.md \
      ${./commands/test-command.md}
  '';
}
