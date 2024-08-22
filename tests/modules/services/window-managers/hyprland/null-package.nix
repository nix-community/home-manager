{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    settings = { "$mod" = "SUPER"; };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"
    assertPathNotExists home-path/bin/hyprctl
  '';
}
