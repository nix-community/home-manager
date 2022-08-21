{
  neovim-plugin-config = ./plugin-config.nix;
  neovim-coc-config = ./coc-config.nix;
  neovim-runtime = ./runtime.nix;

  # waiting for a nixpkgs patch
  neovim-no-init = ./no-init.nix;
}
