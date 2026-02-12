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
      -- initLua
    ''}
  '';
}
