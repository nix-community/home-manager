{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  xsettingsd-basic-configuration = ./basic-configuration.nix;
}
