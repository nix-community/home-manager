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
    assertFileExists "$initLua"
    assertFileContains "$initLua" "python3_host_prog="
    assertFileContains "$initLua" "loaded_node_provider=0"
  '';
}
