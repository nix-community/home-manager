{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  retroarch-cores = ./cores.nix;
  retroarch-settings = ./settings.nix;
}
