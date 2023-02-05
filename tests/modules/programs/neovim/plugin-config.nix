{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      extraConfig = ''
        let g:hmExtraConfig='HM_EXTRA_CONFIG'
      '';
      plugins = with pkgs.vimPlugins; [
        vim-nix
        {
          plugin = vim-commentary;
          config = ''
            let g:hmPlugins='HM_PLUGINS_CONFIG'
          '';
        }
      ];
      extraLuaPackages = [ pkgs.lua51Packages.luautf8 ];
    };

    nmt.script = ''
      vimout=$(mktemp)
      echo "redir >> /dev/stdout | echo g:hmExtraConfig | echo g:hmPlugins | redir END" \
        | ${pkgs.neovim}/bin/nvim -es -u "$TESTED/home-files/.config/nvim/init.lua" \
        > "$vimout"
      assertFileContains "$vimout" "HM_EXTRA_CONFIG"
      assertFileContains "$vimout" "HM_PLUGINS_CONFIG"
    '';
  };
}

