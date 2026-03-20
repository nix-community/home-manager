{
  programs.claude-code = {
    enable = true;
    rulesDir = ./rules;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/rules/test-rule.md
    assertLinkExists home-files/.claude/rules/test-rule.md
    assertFileContent \
      home-files/.claude/rules/test-rule.md \
      ${./rules/test-rule.md}
  '';
}
