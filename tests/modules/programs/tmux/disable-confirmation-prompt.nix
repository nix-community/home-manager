{ config, lib, pkgs, ... }:

with lib;

let

  substituteExpected = path: pkgs.substituteAll {
    src = path;

    sensible_rtp = pkgs.tmuxPlugins.sensible.rtp;
  };
  
in

{
  config = {
    programs.tmux = {
      enable = true;
      disableConfirmationPrompt = true;
    };
  
    nmt.script = ''
      assertFileExists home-files/.tmux.conf
      assertFileContent home-files/.tmux.conf \
        ${substituteExpected ./disable-confirmation-prompt.conf}
    '';
  };
}
