{ lib, realPkgs, ... }: {
  imports = [ ./stubs.nix ];

  # TODO: remove after stubbing `withPackages`
  _module.args.pkgs = lib.mkForce realPkgs;
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
