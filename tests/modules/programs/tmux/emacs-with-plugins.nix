{ config, lib, pkgs, ... }:

with lib;

let

  substituteExpected = path: pkgs.substituteAll {
    src = path;

    tmuxplugin_fzf_tmux_url = pkgs.tmuxPlugins.fzf-tmux-url;
    tmuxplugin_logging = pkgs.tmuxPlugins.logging;
    tmuxplugin_prefix_highlight = pkgs.tmuxPlugins.prefix-highlight;
    tmuxplugin_sensible_rtp = pkgs.tmuxPlugins.sensible.rtp;
  };

in

{
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
      assertFileExists home-files/.tmux.conf
      assertFileContent home-files/.tmux.conf \
        ${substituteExpected ./emacs-with-plugins.conf}
    '';
  };
}
