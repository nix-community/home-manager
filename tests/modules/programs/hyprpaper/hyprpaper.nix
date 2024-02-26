{ ... }:

{
  programs.hyprpaper = {
    enable = true;
    systemd.enable = true;
    settings = {
      preload = [ "/path/to/image.png" "/path/to/next_image.png" ];
      wallpapers =
        [ "monitor1,/path/to/image.png" "monitor2,/path/to/next_image.png" ];
    };
    extraConfig = ''
      splash = true
      ipc = off
    '';
  };

  test.stubs.hyprpaper = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/hyprpaper.service

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/hyprpaper'

    assertFileExists home-files/.config/hypr/hyprpaper.conf
    assertFileContent home-files/.config/hypr/hyprpaper.conf ${./hyprpaper.conf}
  '';
}
