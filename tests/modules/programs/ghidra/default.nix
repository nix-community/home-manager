{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ghidra-basic-configuration = ./basic-configuration.nix;
}
