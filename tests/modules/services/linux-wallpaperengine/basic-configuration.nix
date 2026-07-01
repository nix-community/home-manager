{
  services.linux-wallpaperengine = {
    enable = true;
    assetsPath = "/some/path/to/assets";
    fps = 6;
    audio = {
      silent = true;
      automute = false;
      processing = false;
    };
    wallpapers = [
      {
        monitor = "HDMI-1";
        wallpaper = "12345678";
        scaling = "fit";
      }
      {
        monitor = "DP-1";
        playlist = "config.json";
        extraOptions = [
          "--scaling fill"
        ];
      }
    ];
  };

  nmt.script = ''
    assertFileContent \
        home-files/.config/systemd/user/linux-wallpaperengine.service \
        ${./basic-configuration-expected.service}
  '';
}
