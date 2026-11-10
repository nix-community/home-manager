{
  programs.codex = {
    enable = true;
    package = null;
    accounts = {
      first.home = ".duplicate";
      second.home = ".duplicate";
    };
  };
  test.asserts.assertions.expected = [
    "programs.codex.accounts must use distinct home directories."
  ];
}
