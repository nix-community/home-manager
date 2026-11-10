{
  programs.claude-code = {
    enable = true;
    package = null;
    accounts = {
      first.home = ".duplicate";
      second.home = ".duplicate";
    };
  };
  test.asserts.assertions.expected = [
    "programs.claude-code.accounts must use distinct home directories."
  ];
}
