{
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;

    extraLuaConfig = ''
      -- extraLuaConfig
    '';
  };

  nmt.script = ''
    nvimFolder="home-files/.config/nvim"
    assertFileContent "$nvimFolder/init.lua" ${
      builtins.toFile "init.lua-expected" ''
        -- extraLuaConfig
      ''
    }
  '';
}
