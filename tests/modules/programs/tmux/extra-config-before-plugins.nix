{ config, lib, pkgs, ... }:
with lib; {
  config = {
    programs.tmux = {
      enable = true;
      mouse = true;
      extraConfigBeforePlugins = ''
        set -g mouse off
      '';

      plugins = with pkgs.tmuxPlugins; [ logging ];
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
        ${./mouse-enabled.conf}
    '';
  };
}
