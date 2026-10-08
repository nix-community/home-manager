{
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    fastSyntaxHighlighting.enable = true;
  };

  test.asserts.assertions.expected = [
    ''
      Only one Zsh syntax highlighter can be enabled at a time.
    ''
  ];
}
