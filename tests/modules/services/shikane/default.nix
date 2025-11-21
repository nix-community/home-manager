{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  shikane-basic-configuration = ./basic-configuration.nix;
}
