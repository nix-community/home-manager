{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      extraRuntime = {
        "colors/cool.vim".text = ''
          "Very cool colorscheme
        '';
      };
      plugins = with pkgs.vimPlugins; [
        vim-nix
        {
          plugin = vim-commentary;
          # Adding runtimes should not add anything to the config
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
      nvimFolder="home-files/.config/nvim"

      assertFileExists "$nvimFolder/after/ftplugin/c.vim"
      assertFileExists "$nvimFolder/colors/cool.vim"
      assertPathNotExists "$nvimFolder/init.lua"
    '';
  };
}

