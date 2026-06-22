{
  programs.chromium = {
    enable = true;
    package = null;
    commandLineArgs = [ "--enable-logging=stderr" ];
  };

  test.asserts.assertions.expected = [
    "Cannot set `commandLineArgs` when `package` is null for chromium."
  ];
}
