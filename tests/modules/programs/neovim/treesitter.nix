{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    treesitter.enable = true;
  };
  nmt.script = ''
    assertFileContent "home-files/.config/nvim/init.lua" ${
      pkgs.writeText "init.lua-expected" ''
        require('nvim-treesitter.configs').setup {
          -- auto_install is not reproducible
          auto_install = false,
          highlight = {
            enable = true,
            disable = {  },
            -- docs claim that this slows down the editor and mostly not needed
            additional_vim_regex_highlighting = false,
          };
        }
      ''
    };
  '';
}
