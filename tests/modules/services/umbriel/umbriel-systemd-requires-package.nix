{
  wayland.windowManager.umbriel = {
    enable = true;
    package = null;
    portalPackage = null;
    # systemd.enable defaults to true
  };

  test.asserts.assertions.expected = [
    "wayland.windowManager.umbriel.systemd.enable requires a non-null package"
  ];
}
