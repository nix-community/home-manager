{
  home.stateVersion = "25.11";

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
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
