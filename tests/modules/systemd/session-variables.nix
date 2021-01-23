{ config, lib, pkgs, ... }:

with lib;

let
  expectedConf = pkgs.substituteAll {
    src = ./session-variables-expected.conf;
    inherit (pkgs) glibcLocales;
  };
in {
  config = {
    systemd.user.sessionVariables = {
      V_int = 1;
      V_str = "2";
    };

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContent $envFile ${expectedConf}
    '';
  };
}
