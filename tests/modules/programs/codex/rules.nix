{
  programs.codex = {
    enable = true;
    rules = {
      default = builtins.toFile "default.rules" ''
        prefix_rule(
          pattern = ["git", "status"],
          decision = "allow",
          justification = "Allow routine status checks",
        )
      '';
      github = ''
        prefix_rule(
          pattern = ["gh", "pr", "view"],
          decision = "prompt",
          justification = "Review PRs with confirmation",
        )
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.codex/rules/default.rules
    assertFileContent home-files/.codex/rules/default.rules \
      ${builtins.toFile "expected-default.rules" ''
        prefix_rule(
          pattern = ["git", "status"],
          decision = "allow",
          justification = "Allow routine status checks",
        )
      ''}

    assertFileExists home-files/.codex/rules/github.rules
    assertFileContent home-files/.codex/rules/github.rules \
      ${builtins.toFile "expected-github.rules" ''
        prefix_rule(
          pattern = ["gh", "pr", "view"],
          decision = "prompt",
          justification = "Review PRs with confirmation",
        )
      ''}
  '';
}
