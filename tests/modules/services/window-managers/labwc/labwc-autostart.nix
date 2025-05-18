{
  wayland.windowManager.labwc = {
    enable = true;
    package = null;
    autostart = [
      "wayvnc &"
      "waybar &"
      "swaybg -c '#113344' >/dev/null 2>&1 &"
    ];
  };

  nmt.script = ''
    labwcAutostart=home-files/.config/labwc/autostart

    assertFileExists "$labwcAutostart"
    assertFileContent $(normalizeStorePaths "$labwcAutostart") "${./autostart}"
  '';
}
