{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xsession.numlock.enable = true;

    test.stubs.numlockx = { };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/numlockx.service
      assertFileExists $serviceFile
    '';
  };
}
