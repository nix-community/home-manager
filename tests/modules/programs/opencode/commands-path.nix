{
  programs.opencode = {
    enable = true;
    commands = {
      test-command = ./test-command.md;
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/command/test-command.md
    assertFileContent home-files/.config/opencode/command/test-command.md \
      ${./test-command.md}
  '';
}
