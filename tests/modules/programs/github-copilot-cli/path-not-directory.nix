{
  programs.github-copilot-cli = {
    enable = true;
    agents = ./agents/code-reviewer.agent.md;
    skills = ./skills/data-analysis/SKILL.md;
  };

  test.asserts.assertions.expected = [
    "`programs.github-copilot-cli.agents` must be a directory when set to a path"
    "`programs.github-copilot-cli.skills` must be a directory when set to a path"
  ];
}
