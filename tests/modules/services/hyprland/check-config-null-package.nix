{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    configType = "lua";
    portalPackage = null;
    checkConfig = true;
    systemd.enable = false;
  };

  test.asserts.assertions.expected = [
    "wayland.windowManager.hyprland.checkConfig requires non-null wayland.windowManager.hyprland.package"
  ];
}
