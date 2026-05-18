{
  programs.cursor-agent = {
    enable = true;
    package = null;

    commandsDir = ./commands;
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/commands/test-command.md
    assertFileContent home-files/.cursor/commands/test-command.md \
      ${./commands/test-command.md}
  '';
}
