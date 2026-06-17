{
  programs.uv = {
    enable = true;
    package = null;
    tool.packages = [ "ruff" ];
  };

  test.asserts.assertions.expected = [
    ''
      `programs.uv.package` cannot be null when `programs.uv.python` or
      `programs.uv.tool` manages installations during activation.
    ''
  ];
}
