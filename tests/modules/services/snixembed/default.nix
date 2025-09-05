{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  snixembed-basic-configuration = ./basic-configuration.nix;
}
