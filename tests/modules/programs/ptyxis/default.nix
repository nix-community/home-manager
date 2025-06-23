{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ptyxis-basic-palette = ./palette.nix;
}
