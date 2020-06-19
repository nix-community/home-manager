{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.fzf.enable = true;

    programs.vim = {
      enable = true;

      plugins = [ pkgs.vimPlugins.ack-vim ];
      optionalPlugins = [ pkgs.vimPlugins.fzf-vim ];
    };

    nmt.script = ''
      assertDirectoryExists home-path/share/vim-plugins/fzf
    '';
  };
}
