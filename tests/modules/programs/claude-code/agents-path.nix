{
  programs.claude-code = {
    enable = true;
    agents = {
      test-agent = ./test-agent.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/agents/test-agent.md
    assertFileContent home-files/.claude/agents/test-agent.md \
      ${./test-agent.md}
  '';
}
