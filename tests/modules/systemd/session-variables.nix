{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    systemd.user.sessionVariables = {
      V_int = 1;
      V_str = "2";
    };

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContent $envFile ${./session-variables-expected.conf}
    '';
  };
}
