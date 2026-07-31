{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    checkConfig = true;

    settings = {
      "$mod" = "SUPER";
    };
  };

  test.asserts.assertions.expected = [
    "wayland.windowManager.hyprland.checkConfig requires non-null wayland.windowManager.hyprland.package"
  ];

  nmt.script = "";
}
