{
  programs.warp-terminal = {
    enable = true;
    package = null;
    validateSettings = true;
  };

  test.asserts.assertions.expected = [
    "programs.warp-terminal.validateSettings requires programs.warp-terminal.package to provide the settings schema."
  ];
}
