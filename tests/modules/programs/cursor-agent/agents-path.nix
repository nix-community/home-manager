{
  programs.cursor-agent = {
    enable = true;
    package = null;

    agents = {
      test-agent = ./agents/test-agent.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/agents/test-agent.md
    assertFileContent home-files/.cursor/agents/test-agent.md \
      ${./agents/test-agent.md}
  '';
}
