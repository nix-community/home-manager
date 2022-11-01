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
      ];
      extraLuaPackages = [ pkgs.lua51Packages.luautf8 ];
    };

    nmt.script = ''
      vimrc="$TESTED/home-files/.config/nvim/init-home-manager.vim"
      vimrcNormalized="$(normalizeStorePaths "$vimrc")"

      assertFileExists "$vimrc"
      assertFileContent "$vimrcNormalized" "${./plugin-config.vim}"
    '';
  };
}

