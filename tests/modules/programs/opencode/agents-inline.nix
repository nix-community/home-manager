{
  programs.opencode = {
    enable = true;
    agents = {
      code-reviewer = ''
        # Code Reviewer Agent

        You are a senior software engineer specializing in code reviews.
        Focus on code quality, security, and maintainability.

        ## Guidelines
        - Review for potential bugs and edge cases
        - Check for security vulnerabilities
        - Ensure code follows best practices
        - Suggest improvements for readability and performance
      '';
      documentation = ''
        # Documentation Agent

        You are a technical writer who creates clear, comprehensive documentation.
        Focus on user-friendly explanations and examples.

        ## Guidelines
        - Write clear, concise documentation
        - Include practical examples
        - Use proper formatting and structure
        - Consider the target audience
      '';
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/agent/code-reviewer.md
    assertFileExists home-files/.config/opencode/agent/documentation.md
    assertFileContent home-files/.config/opencode/agent/code-reviewer.md \
      ${./code-reviewer-agent.md}
    assertFileContent home-files/.config/opencode/agent/documentation.md \
      ${./documentation-agent.md}
  '';
}
