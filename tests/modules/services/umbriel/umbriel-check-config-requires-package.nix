{
  wayland.windowManager.umbriel = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    checkConfig = true;
  };

  test.asserts.assertions.expected = [
    "wayland.windowManager.umbriel.checkConfig requires a non-null package"
  ];
}
