{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  equibop-basic-configuration = ./basic-configuration.nix;
}
