{ pkgs, ... }:
{
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;
    plugins = [
      {
        plugin = pkgs.vimPlugins.vim-nix;
        type = "lua";
      }
    ];
  };

  nmt.script = ''
    initLua="home-files/.config/nvim/init.lua"
    assertPathNotExists "$initLua"
  '';
}
