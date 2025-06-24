{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  barrier-basic-configuration = ./basic-configuration.nix;
}
