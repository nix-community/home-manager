{
  home.stateVersion = "25.11";

  wayland.windowManager.hyprland = {
    enable = true;
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
