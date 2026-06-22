{
  programs.opencode = {
    enable = true;
    agents = {
      test-agent = ./test-agent.md;
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/agents/test-agent.md
    assertFileContent home-files/.config/opencode/agents/test-agent.md \
      ${./test-agent.md}
  '';
}
