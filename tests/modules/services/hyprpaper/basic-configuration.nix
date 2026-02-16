{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = [
        "/share/wallpapers/buttons.png"
        "/share/wallpapers/cat_pacman.png"
      ];

      wallpaper = [
        {
          monitor = "DP-3";
          path = "/share/wallpapers/buttons.png";
          fit_mode = "cover";
        }
        {
          monitor = "DP-2";
          path = "/share/wallpapers/cat_pacman.png";
          fit_mode = "cover";
        }
        {
          monitor = "";
          path = "~/fallback.jxl";
          fit_mode = "cover";
        }
      ];
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprpaper.conf
    clientServiceFile=home-files/.config/systemd/user/hyprpaper.service
    assertFileExists $config
    assertFileExists $clientServiceFile
    assertFileContent $config ${./hyprpaper.conf}
  '';
}
