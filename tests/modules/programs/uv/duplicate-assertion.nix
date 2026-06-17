{
  programs.uv = {
    enable = true;
    python.versions = [
      "3.12"
      "3.13"
      "3.12"
    ];
  };

  test.stubs.uv.name = "uv";

  test.asserts.assertions.expected = [
    ''
      programs.uv.python.versions contains duplicate entries: "3.12".
    ''
  ];
}
