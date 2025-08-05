{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  sherlock-default-configuration = ./default-configuration.nix;
  sherlock-basic-configuration = ./basic-configuration.nix;
  sherlock-full-configuration = ./full-configuration.nix;
  sherlock-empty-settings = ./empty-settings.nix;
}
