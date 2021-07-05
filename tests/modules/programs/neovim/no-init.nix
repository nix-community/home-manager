{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-unwrapped;
      vimAlias = true;
      withNodeJs = false;
      withPython3 = true;
      withRuby = false;

      extraPython3Packages = (ps: with ps; [ jedi pynvim ]);
    };
    nmt.script = ''
      vimrc="home-files/.config/nvim/init.vim"
      assertPathNotExists "$vimrc"
    '';
  };
}
