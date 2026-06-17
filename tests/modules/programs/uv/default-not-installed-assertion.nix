{
  programs.uv = {
    enable = true;
    python = {
      versions = [ "3.12" ];
      default = [ "3.13" ];
    };
  };

  test.stubs.uv.name = "uv";

  test.asserts.assertions.expected = [
    ''
      Every programs.uv.python.default entry must also be listed, spelled
      identically, in programs.uv.python.versions.
    ''
  ];
}
