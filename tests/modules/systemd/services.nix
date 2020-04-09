{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    systemd.user.services."test-service@" = {
      Unit = {
        Description = "A basic test service";
      };

      Service = {
        ExecStart = ''/some/exec/start/command --with-arguments "%i"'';
      };
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/test-service@.service
      assertFileExists $serviceFile
      assertFileContent $serviceFile ${./services-expected.conf}
    '';
  };
}
