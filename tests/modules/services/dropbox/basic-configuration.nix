{ config, pkgs, ... }:

{
  services.dropbox = {
    enable = true;
    path = "${config.home.homeDirectory}/dropbox";
  };

  test.stubs.dropbox = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/dropbox.service

    assertFileExists $serviceFile
  '';
}
