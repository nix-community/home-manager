{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.homeDirectory = "/homeless-shelter";

    targets.genericLinux.enable = true;

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileContent \
        home-path/etc/profile.d/hm-session-vars.sh \
        ${
          pkgs.substituteAll {
            src = ./generic-linux-session-vars-expected.txt;
            nix = pkgs.nix;
          }
        }
    '';
  };
}
