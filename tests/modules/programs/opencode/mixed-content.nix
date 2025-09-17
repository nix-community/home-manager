{
  programs.opencode = {
    enable = true;
    commands = {
      inline-command = ''
        # Inline Command
        This command is defined inline.
      '';
      path-command = ./test-command.md;
    };
    agents = {
      inline-agent = ''
        # Inline Agent
        This agent is defined inline.
      '';
      path-agent = ./test-agent.md;
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/command/inline-command.md
    assertFileExists home-files/.config/opencode/command/path-command.md
    assertFileExists home-files/.config/opencode/agent/inline-agent.md
    assertFileExists home-files/.config/opencode/agent/path-agent.md

    assertFileContent home-files/.config/opencode/command/path-command.md \
      ${./test-command.md}
    assertFileContent home-files/.config/opencode/agent/path-agent.md \
      ${./test-agent.md}
  '';
}
