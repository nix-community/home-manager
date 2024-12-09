{ pkgs, ... }:

{
  services.hypridle.enable = true;

  test.stubs.hypridle = { };

  nmt.script = ''
    config=home-files/.config/hypr/hypridle.conf
    clientServiceFile=home-files/.config/systemd/user/hypridle.service
    assertPathNotExists $config
    assertFileExists $clientServiceFile
  '';
}
