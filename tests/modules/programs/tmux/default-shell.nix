{ config, lib, pkgs, ... }:

with lib;

let

  substituteExpected = path:
    pkgs.substituteAll {
      src = path;

      sensible_rtp = pkgs.tmuxPlugins.sensible.rtp;
    };

in {
  config = {
    programs.tmux = {
      enable = true;
      shell = "/usr/bin/myshell";
    };

    nmt.script = ''
      assertFileExists home-files/.config/tmux/tmux.conf
      assertFileContent home-files/.config/tmux/tmux.conf \
        ${substituteExpected ./default-shell.conf}
    '';
  };
}
