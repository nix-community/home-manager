{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    settings = {
      cursor = {
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
      };
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"
  '';
}
