{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  conky-basic-configuration = ./basic-configuration.nix;
}
