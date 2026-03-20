{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  twmn-basic-configuration = ./basic-configuration.nix;
}
