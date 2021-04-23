{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.tmux = {
      enable = true;
      disableConfirmationPrompt = true;
    };

    nixpkgs.overlays = [
      (self: super: {
        tmuxPlugins = super.tmuxPlugins // {
          sensible = super.tmuxPlugins.sensible // { rtp = "@sensible_rtp@"; };
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/tmux/tmux.conf
      assertFileContent home-files/.config/tmux/tmux.conf \
        ${./disable-confirmation-prompt.conf}
    '';
  };
}
