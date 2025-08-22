{
  programs.claude-code = {
    enable = true;
    agentsDir = ./agents;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/agents/test-agent.md
    assertLinkExists home-files/.claude/agents/test-agent.md
    assertFileContent \
      home-files/.claude/agents/test-agent.md \
      ${./agents/test-agent.md}
  '';
}
