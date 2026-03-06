{
  programs.claude-code = {
    enable = true;
    outputStyles = {
      inline-style = ''
        # Inline Output Style

        This is an inline output style for testing.
        It should be written to .claude/output-styles/inline-style.md
      '';
      path-style = ./test-output-style.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/output-styles/inline-style.md
    assertFileExists home-files/.claude/output-styles/path-style.md

    assertFileContent home-files/.claude/output-styles/path-style.md \
      ${./test-output-style.md}

    assertFileRegex home-files/.claude/output-styles/inline-style.md \
      'This is an inline output style for testing'
  '';
}
