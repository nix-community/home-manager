{
  wayland.windowManager.niri = {
    enable = true;
    checkConfig = false;
    portalPackage = null;
    systemd.enable = false;
    xwaylandSatellitePackage = null;

    enableDefaultConfig = true;
    package = null;
  };

  test.asserts.assertions.expected = [
    "wayland.windowManager.niri.enableDefaultConfig requires a package with a string-like `src` attribute"
  ];
}
