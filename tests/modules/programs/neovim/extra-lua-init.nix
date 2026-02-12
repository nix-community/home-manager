{
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;

    initLua = ''
      -- initLua
    '';
  };

  nmt.script = ''
    initLua="home-files/.config/nvim/init.lua"
    initLuaNormalized="$(normalizeStorePaths "$initLua")"

    assertFileContent "$initLuaNormalized" ${builtins.toFile "init.lua-expected" ''
      vim.g.loaded_node_provider=0;vim.g.loaded_perl_provider=0;vim.g.loaded_python_provider=0;vim.g.python3_host_prog='/nix/store/00000000000000000000000000000000-hm_nviminit.lua/bin/nvim-python3';vim.g.ruby_host_prog='/nix/store/00000000000000000000000000000000-hm_nviminit.lua/bin/nvim-ruby'


      -- initLua
      ''}
  '';
}
