{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = lib.mkMerge [
      {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          vim-nix
          {
            plugin = vim-commentary;
            runtime = {
              "after/ftplugin/c.vim".text = ''
                " plugin-specific config
                setlocal commentstring=//\ %s
                setlocal comments=://
              '';
            };
          }
        ];
      }
      {
        extraPython3Packages = ps: with ps; [ jedi pynvim ];
        extraLuaPackages = ps: with ps; [ luacheck ];
      }
      {
        extraPython3Packages = with pkgs.python3Packages; [ jedi pynvim ];
        extraLuaPackages = with pkgs.lua51Packages; [ luacheck ];
      }
    ];

    nmt.script = ''
      ftplugin="home-files/.config/nvim/after/ftplugin/c.vim"
      assertFileExists "$ftplugin"
    '';
  };
}
