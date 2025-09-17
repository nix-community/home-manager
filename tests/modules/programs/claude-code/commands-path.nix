{
  programs.claude-code = {
    enable = true;
    commands = {
      test-command = ./test-command.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/commands/test-command.md
    assertFileContent home-files/.claude/commands/test-command.md \
      ${./test-command.md}
  '';
}
