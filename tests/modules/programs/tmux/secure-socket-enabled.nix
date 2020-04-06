{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.tmux = {
      enable = true;
      secureSocket = true;
    };

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileContent home-path/etc/profile.d/hm-session-vars.sh ${
        ./hm-session-vars.sh
      }
    '';
  };
}
