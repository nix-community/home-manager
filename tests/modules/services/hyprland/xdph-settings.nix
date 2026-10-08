{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;

    xdph.settings.general.toplevel_dynamic_bind = true;

    xdph.settings.screencopy = {
      max_fps = 60;
      allow_token_by_default = true;
      custom_picker_binary = "hyprland-share-picker";
      force_shm = true;
      cursor_mode = 2;
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/xdph.conf
    assertFileExists "$config"
    assertFileContent "$config" ${./xdph.conf}
  '';
}
