{
  programs.diff-highlight = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    package = null;
  };

  test.asserts.assertions.expected = [
    ''
      programs.diff-highlight.enableGitIntegration requires programs.git.package to be set.
      Please set programs.git.package to a valid git package.
    ''
  ];
}
