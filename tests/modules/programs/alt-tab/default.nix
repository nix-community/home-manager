{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  alt-tab-defaults = ./defaults.nix;
  alt-tab-disabled = ./disabled.nix;
  alt-tab-shortcut = ./shortcut.nix;
  alt-tab-null-package = ./null-package.nix;
}
