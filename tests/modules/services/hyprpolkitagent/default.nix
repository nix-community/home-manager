{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprpolkitagent-basic-configuration = ./basic-configuration.nix;
}
