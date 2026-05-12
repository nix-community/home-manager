{
  home.stateVersion = "26.05";

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    package = null;
    portalPackage = null;
    systemd.enable = false;
    settings = {
      "$mod" = "SUPER";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/hypr/hyprland.conf
    assertPathNotExists home-files/.config/hypr/hyprland.lua
  '';
}
