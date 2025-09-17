{
  programs.claude-code = {
    enable = true;
    commands = {
      inline-command = ''
        ---
        allowed-tools: Read
        description: Inline command
        ---
        This command is defined inline.
      '';
      path-command = ./test-command.md;
    };
    agents = {
      inline-agent = ''
        ---
        name: inline-agent
        description: Inline agent
        tools: Read
        ---
        This agent is defined inline.
      '';
      path-agent = ./test-agent.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/commands/inline-command.md
    assertFileExists home-files/.claude/commands/path-command.md
    assertFileExists home-files/.claude/agents/inline-agent.md
    assertFileExists home-files/.claude/agents/path-agent.md

    assertFileContent home-files/.claude/commands/path-command.md \
      ${./test-command.md}
    assertFileContent home-files/.claude/agents/path-agent.md \
      ${./test-agent.md}
  '';
}
