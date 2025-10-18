{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  autotiling-basic-config = ./autotiling-basic-config.nix;
}
