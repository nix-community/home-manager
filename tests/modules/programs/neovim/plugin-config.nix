{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      extraConfig = ''
        " This 'extraConfig' should be present in vimrc
      '';
      plugins = with pkgs.vimPlugins; [
        vim-nix
        {
          plugin = vim-commentary;
          config = ''
            " plugin-specific config
            autocmd FileType c setlocal commentstring=//\ %s
            autocmd FileType c setlocal comments=://
          '';
        }
        {
          plugin = range-highlight-nvim;
          type = "lua";
          config = ''
            -- lua config
            require('range-highlight').setup{}
          '';
        }
      ];
      extraLuaPackages = [ pkgs.lua51Packages.luautf8 ];
    };

    nmt.script = ''
      viml="$(normalizeStorePaths "$TESTED/home-files/.config/nvim/vim/home-manager-viml.vim")"
      lua="$(normalizeStorePaths "$TESTED/home-files/.config/nvim/lua/home-manager-lua.lua")"

      assertFileContent "$viml" "${builtins.toFile "exepected-viml.vim" ''
        " plugin-specific config
        autocmd FileType c setlocal commentstring=//\ %s
        autocmd FileType c setlocal comments=://

        " This 'extraConfig' should be present in vimrc
      ''}"

      assertFileContent "$lua" "${builtins.toFile "exepected-lua.lua" ''
        -- lua config
        require('range-highlight').setup{}
      ''}"
    '';
  };
}

