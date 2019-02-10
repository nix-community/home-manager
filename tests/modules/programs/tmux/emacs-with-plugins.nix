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
      keyMode = "emacs";
      newSession = true;
      reverseSplit = true;

      plugins = with pkgs.tmuxPlugins; [
        logging
        prefix-highlight
        fzf-tmux-url
      ];
    };

    nmt.script = ''
      if assertFileExists home-files/.tmux.conf; then
        assertFileContent home-files/.tmux.conf ${substituteExpected ./emacs-with-plugins.conf}
      fi
    '';
  };
}
