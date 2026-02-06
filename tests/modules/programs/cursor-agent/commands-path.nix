{
  programs.cursor-agent = {
    enable = true;
    package = null;

    commands = {
      test-command = ./commands/test-command.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/commands/test-command.md
    assertFileContent home-files/.cursor/commands/test-command.md \
      ${./commands/test-command.md}
  '';
}
