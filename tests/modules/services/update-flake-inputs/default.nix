{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  update-flake-inputs-basic = ./basic.nix;
  update-flake-inputs-full = ./full.nix;
}
