{
  programs.pi-coding-agent = {
    enable = true;
    package = null;
    accounts = {
      first.home = ".duplicate";
      second.home = ".duplicate";
    };
  };
  test.asserts.assertions.expected = [
    "programs.pi-coding-agent.accounts must use distinct home directories."
  ];
}
