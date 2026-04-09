{
  neovim-plugin-config = ./plugin-config.nix;
  neovim-coc-config = ./coc-config.nix;
  neovim-runtime = ./runtime.nix;
  neovim-wrapper-args = ./wrapper-args.nix;

  neovim-no-init-vim = ./no-init-vim.nix;
  neovim-extra-lua-init = ./extra-lua-init.nix;
  neovim-extra-lua-default = ./extra-lua-default.nix;
  neovim-extra-lua-empty-plugin = ./extra-lua-empty-plugin.nix;

  neovim-sideload-init-lua = ./sideload-init-lua.nix;
}
