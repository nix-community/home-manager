{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
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

      extraPython3Packages = (ps: with ps; [ jedi pynvim ]);
    };
    nmt.script = ''
      ftplugin="home-files/.config/nvim/after/ftplugin/c.vim"
      assertFileExists "$ftplugin"
    '';
  };
}

