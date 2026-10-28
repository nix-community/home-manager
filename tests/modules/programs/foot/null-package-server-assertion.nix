{
  programs.foot = {
    enable = true;
    package = null;
    server.enable = true;
  };

  test.asserts.assertions.expected = [
    "programs.foot.server.enable requires a non-null programs.foot.package"
  ];
}
