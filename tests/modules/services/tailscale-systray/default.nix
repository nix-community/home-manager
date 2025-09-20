{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  basic = ./basic.nix;
}
