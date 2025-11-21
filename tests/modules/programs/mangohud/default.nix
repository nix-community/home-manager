{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mangohud-basic-configuration = ./basic-configuration.nix;
}
