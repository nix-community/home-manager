{
  services.linux-wallpaperengine = {
    enable = true;
    wallpapers = [
      {
        monitor = "HDMI-A-1";
        wallpaper = "2902931482";
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
        home-files/.config/systemd/user/linux-wallpaperengine.service \
        ${./missing-spaces-expected.service}
  '';
}
