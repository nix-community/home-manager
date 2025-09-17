{
  programs.opencode = {
    enable = true;
    agents = {
      test-agent = ./test-agent.md;
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/agent/test-agent.md
    assertFileContent home-files/.config/opencode/agent/test-agent.md \
      ${./test-agent.md}
  '';
}
