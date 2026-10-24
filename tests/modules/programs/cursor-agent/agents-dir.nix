{
  programs.cursor-agent = {
    enable = true;
    package = null;

    agentsDir = ./agents;
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/agents/test-agent.md
    assertFileContent home-files/.cursor/agents/test-agent.md \
      ${./agents/test-agent.md}
  '';
}
