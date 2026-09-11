{
  test.asserts.assertions.expected = [
    "home.file: mutable files require the legacy file activator."
  ];

  home.fileActivator = "putter";
  home.file."app/config" = {
    text = "managed";
    mutable = true;
  };
}
