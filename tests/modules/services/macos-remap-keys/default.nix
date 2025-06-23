{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  macos-remap-keys-basic-configuration = ./basic-configuration.nix;
}
