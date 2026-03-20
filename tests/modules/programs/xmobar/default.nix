{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  xmobar-basic-configuration = ./basic-configuration.nix;
}
