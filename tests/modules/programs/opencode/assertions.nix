{
  programs.opencode = {
    enable = true;
    package = null;
    validateFiles.config = true;
  };

  test.asserts.assertions.expected = [
    "`programs.opencode.validateFiles` requires `programs.opencode.package` to be set"
  ];
}
