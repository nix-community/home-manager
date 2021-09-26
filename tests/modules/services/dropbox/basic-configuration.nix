{ config, pkgs, ... }:

{
  config = {
    services.dropbox = {
      enable = true;
      path = "${config.home.homeDirectory}/dropbox";
    };

    test.stubs.dropbox-cli = { };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/dropbox.service

      assertFileExists $serviceFile
    '';

  };
}
