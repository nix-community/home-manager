{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  freetube-basic-configuration = ./basic-configuration.nix;
}
