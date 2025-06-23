{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  sxhkd-configuration = ./configuration.nix;
  sxhkd-service = ./service.nix;
}
