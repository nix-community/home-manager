{ config, lib, pkgs, ... }:
with lib;
let
  extraConfig = ''
    echo extraConfigVim
  '';
in {
  config = {
    programs.neovim = {
      enable = true;
      inherit extraConfig;
      extraLuaConfig = ''
        -- extraLuaConfig
      '';
    };
    nmt.script = ''
      nvimFolder="home-files/.config/nvim"
      assertFileContent "$nvimFolder/init.lua" ${
        pkgs.writeText "init.lua-expected" ''
          vim.cmd [[source ${
            pkgs.writeText "nvim-init-home-manager.vim" extraConfig
          }]]
          -- extraLuaConfig
        ''
      }
    '';
  };
}
