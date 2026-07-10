{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  openlinkhub-configs = ./configs.nix;
  openlinkhub-minimal = ./minimal.nix;
}
