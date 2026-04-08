{ pkgs, lib, ... }:
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
    nvimFolder="home-files/.config/nvim"
    initLua="home-files/.config/nvim/init.lua"
    initLuaNormalized="$(normalizeStorePaths "$initLua")"

    assertFileContent "$initLuaNormalized" ${builtins.toFile "init.lua-expected" (lib.trim ''
      vim.g.loaded_node_provider=0;vim.g.loaded_perl_provider=0;vim.g.ruby_host_prog='/nix/store/00000000000000000000000000000000-neovim-ruby-env/bin/neovim-ruby-host';vim.g.python3_host_prog='/nix/store/00000000000000000000000000000000-nvim-host-python3/bin/nvim-python3'
    '')}
  '';
}
