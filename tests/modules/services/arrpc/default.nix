{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  arrpc-custom-target = ./custom-target.nix;
}
