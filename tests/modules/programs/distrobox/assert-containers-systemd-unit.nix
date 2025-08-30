{
  programs.distrobox = {
    enable = true;
    enableSystemdUnit = true;
  };

  test.asserts.assertions.expected = [
    "Cannot set `programs.distrobox.enableSystemdUnit` if `programs.distrobox.containers` is unset."
  ];
}
