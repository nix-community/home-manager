{
  services.linux-wallpaperengine = {
    enable = true;
    clamping = "clamp";
    wallpapers = [
      {
        monitor = "HDMI-1";
        wallpaper = "12345678";
      }
      {
        monitor = "DP-1";
        wallpaper = "87654321";
        clamp = "border";
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
        home-files/.config/systemd/user/linux-wallpaperengine.service \
        ${./clamping-legacy-expected.service}
  '';
}
