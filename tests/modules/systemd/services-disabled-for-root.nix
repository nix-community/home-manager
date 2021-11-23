{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.username = mkForce "root";

    systemd.user.services."test-service@" = {
      Unit = { Description = "A basic test service"; };

      Service = {
        Environment = [ "VAR1=1" "VAR2=2" ];
        ExecStart = ''/some/exec/start/command --with-arguments "%i"'';
      };
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/test-service@.service
      assertPathNotExists $serviceFile
    '';
  };
}
