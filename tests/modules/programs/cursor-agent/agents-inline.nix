{
  programs.cursor-agent = {
    enable = true;
    package = null;

    agents = {
      code-reviewer = ''
        ---
        name: code-reviewer
        description: Specialized code review agent
        ---

        You are a senior software engineer specializing in code reviews.
        Focus on code quality, security, and maintainability.
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/agents/code-reviewer.md
    assertFileContent home-files/.cursor/agents/code-reviewer.md \
      ${./expected-code-reviewer-agent.md}
  '';
}
