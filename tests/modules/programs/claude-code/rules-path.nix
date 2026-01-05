{
  programs.claude-code = {
    enable = true;
    rules = {
      test-rule = ./test-rule.md;
      inline-rule = ''
        # Inline Rule

        This is an inline rule for testing.
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/rules/test-rule.md
    assertFileContent home-files/.claude/rules/test-rule.md \
      ${./test-rule.md}
    assertFileExists home-files/.claude/rules/inline-rule.md
  '';
}
