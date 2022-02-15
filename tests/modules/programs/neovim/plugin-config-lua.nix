{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      extraConfig = ''
        " This should be present in init.vim
      '';
      plugins = with pkgs.vimPlugins; [
        vim-nix
        {
          plugin = vim-commentary;
          type = "lua";
          config = ''
            -- This should be present in a lua block.
            vim.opt.number = true
          '';
        }
      ];
    };

    nmt.script = ''
      vimrc="$TESTED/home-files/.config/nvim/init.vim"
      vimrcNormalized="$(normalizeStorePaths "$vimrc")"

      assertFileExists "$vimrc"
      assertFileContent "$vimrcNormalized" "${./plugin-config-lua.vim}"
    '';
  };
}

