{
  programs.cursor-agent = {
    enable = true;
    package = null;
    rulesDir = ./rules;
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/rules/test-rule.md
    assertFileContent home-files/.cursor/rules/test-rule.md \
      ${./rules/test-rule.md}
  '';
}
