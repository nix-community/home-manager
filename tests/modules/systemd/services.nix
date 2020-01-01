{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    systemd.user.services."test-service@" = {
      Unit = {
        Description = "A basic test service";
      };

      Service = {
        ExecStartPre = [
          "/some/exec/start/pre/command first-command"
          "/some/exec/start/pre/command second-command"
        ];
        ExecStart = ''/some/exec/start/command --with-arguments "%i"'';
      };
    };

    nmt.script = ''
      local serviceFile=home-files/.config/systemd/user/test-service@.service
      assertFileExists $serviceFile
      assertFileContent $serviceFile ${./services-expected.conf}
    '';
  };
}
