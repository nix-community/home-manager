{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  trayer-basic-configuration = ./basic-configuration.nix;
}
