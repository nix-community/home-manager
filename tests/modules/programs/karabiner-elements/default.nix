{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  karabiner-elements-basic-configuration = ./basic-configuration.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  karabiner-elements-linux = ./linux.nix;
}
