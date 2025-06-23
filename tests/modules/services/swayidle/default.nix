{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swayidle-basic-configuration = ./basic-configuration.nix;
}
