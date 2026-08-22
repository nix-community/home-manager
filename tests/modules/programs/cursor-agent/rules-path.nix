{
  programs.cursor-agent = {
    enable = true;
    package = null;
    rules = {
      test-rule = ./rules/test-rule.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/rules/test-rule.md
    assertFileContent home-files/.cursor/rules/test-rule.md \
      ${./rules/test-rule.md}
  '';
}
