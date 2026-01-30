let
  enable = {
    enable = true;
    enableGitIntegration = true;
  };
in
{
  programs = {
    delta = enable;
    # FIXME(leana8959): these two aren't caught by the tests.
    # diff-highlight = enable;
    # diff-so-fancy = enable;
    patdiff = enable;
  };

  test.asserts.assertions.expected = [
    ''
      Only one of the following options can be enabled at a time.
        - `programs.delta.enableGitIntegration'
        - `programs.patdiff.enableGitIntegration'
    ''
  ];
}
