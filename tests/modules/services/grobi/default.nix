{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  grobi-basic-configuration = ./basic-configuration.nix;
  grobi-default-settings = ./default-settings.nix;
  grobi-disabled = ./disabled.nix;
  grobi-legacy-settings = ./legacy-settings.nix;
  grobi-mixed-settings = ./mixed-settings.nix;
  grobi-priority-settings = ./priority-settings.nix;
}
