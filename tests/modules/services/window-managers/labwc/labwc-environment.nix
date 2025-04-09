{
  wayland.windowManager.labwc = {
    enable = true;
    package = null;
    xwayland.enable = false;
    environment = [
      "XDG_CURRENT_DESKTOP=labwc:wlroots"
      "XKB_DEFAULT_LAYOUT=us"
    ];
  };

  nmt.script = ''
    labwcEnvironment=home-files/.config/labwc/environment

    assertFileExists "$labwcEnvironment"
    assertFileContent "$labwcEnvironment" "${./environment}"
  '';
}
