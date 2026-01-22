{
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;

    initLua = ''
      -- initLua
    '';
  };

  nmt.script = ''
    nvimFolder="home-files/.config/nvim"
    assertFileContent "$nvimFolder/init.lua" ${builtins.toFile "init.lua-expected" ''
      -- initLua
    ''}
  '';
}
