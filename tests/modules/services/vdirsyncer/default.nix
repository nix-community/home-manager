{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  vdirsyncer-basic-configuration = ./basic-configuration.nix;
}
