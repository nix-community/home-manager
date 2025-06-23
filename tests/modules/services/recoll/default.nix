{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  recoll-basic-configuration = ./basic-configuration.nix;
  recoll-config-format-order = ./config-format-order.nix;
}
