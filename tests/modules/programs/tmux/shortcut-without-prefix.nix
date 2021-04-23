{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.tmux = {
      enable = true;
      shortcut = "a";
      prefix = null;
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
        ${./shortcut-without-prefix.conf}
    '';
  };
}
