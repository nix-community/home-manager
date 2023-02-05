{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;

      extraLuaConfig = ''
        -- extraLuaConfig
      '';
    };
    nmt.script = ''
      nvimFolder="home-files/.config/nvim"
      assertFileContent "$nvimFolder/init.lua" ${
        pkgs.writeText "init.lua-expected" ''
          -- extraLuaConfig
        ''
      }
    '';
  };
}
