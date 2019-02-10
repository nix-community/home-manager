{ config, lib, pkgs, ... }:

with lib;

let

  substituteExpected = path: pkgs.substituteAll {
    src = path;

    sensible_rtp = pkgs.tmuxPlugins.sensible.rtp;
  };

in {
  config = {
    programs.tmux = {
      aggressiveResize = true;
      clock24 = true;
      enable = true;
      keyMode = "vi";
      newSession = true;
      reverseSplit = true;
    };

    nmt.script = ''
      assertFileExists home-files/.tmux.conf
      assertFileContent home-files/.tmux.conf \
        ${substituteExpected ./vi-all-true.conf}
    '';
  };
}
