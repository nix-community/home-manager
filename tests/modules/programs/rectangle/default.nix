{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  rectangle-defaults-only = ./defaults-only.nix;
  rectangle-shortcuts-only = ./shortcuts-only.nix;
  rectangle-defaults-and-shortcuts = ./defaults-and-shortcuts.nix;
}
