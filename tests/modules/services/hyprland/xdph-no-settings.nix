{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/hypr/xdph.conf
  '';
}
