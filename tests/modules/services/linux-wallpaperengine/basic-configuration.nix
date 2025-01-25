{ config, pkgs, ... }:

{
  services.linux-wallpaperengine = {
    enable = true;
    assetsPath = "/some/path/to/assets";
    clamping = "border";
    wallpapers = [
      {
        monitor = "HDMI-1";
        wallpaperId = "12345678";
        scaling = "fit";
        fps = 6;
      }
      {
        monitor = "DP-1";
        wallpaperId = "87654321";
        extraOptions = [ "--scaling fill" "--fps 12" ];
        audio = {
          silent = true;
          automute = false;
          processing = false;
        };
      }
    ];
  };

  test.stubs.linux-wallpaperengine = { };

  nmt.script = ''
    assertFileContent \
        home-files/.config/systemd/user/linux-wallpaperengine.service \
        ${./basic-configuration-expected.service}
  '';
}
