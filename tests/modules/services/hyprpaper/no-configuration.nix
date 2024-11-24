{ pkgs, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = { };
  };

  test.stubs.hyprpaper = { };

  nmt.script = ''
    config=home-files/.config/hypr/hyprpaper.conf
    clientServiceFile=home-files/.config/systemd/user/hyprpaper.service
    assertPathNotExists $config
    assertFileExists $clientServiceFile
  '';
}
