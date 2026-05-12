{
  home.stateVersion = "26.05";

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    settings = {
      config.input.kb_layout = "us";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/hypr/hyprland.lua
    assertPathNotExists home-files/.config/hypr/hyprland.conf
  '';
}
