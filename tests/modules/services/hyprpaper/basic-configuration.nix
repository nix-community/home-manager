{ pkgs, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload =
        [ "/share/wallpapers/buttons.png" "/share/wallpapers/cat_pacman.png" ];

      wallpaper = [
        "DP-3,/share/wallpapers/buttons.png"
        "DP-1,/share/wallpapers/cat_pacman.png"
      ];
    };
  };

  test.stubs.hyprpaper = { };

  nmt.script = ''
    config=home-files/.config/hypr/hyprpaper.conf
    clientServiceFile=home-files/.config/systemd/user/hyprpaper.service
    assertFileExists $config
    assertFileExists $clientServiceFile
    assertFileContent $config ${./hyprpaper.conf}
  '';
}
