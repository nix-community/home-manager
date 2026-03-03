{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pegasus-frontend-assets-configuration = ./assets-configuration.nix;
  pegasus-frontend-basic-configuration = ./basic-configuration.nix;
  pegasus-frontend-collections-configuration = ./collections-configuration.nix;
  pegasus-frontend-collectionMerge-configuration = ./collectionMerge-configuration.nix;
  pegasus-frontend-favorites-configuration = ./favorites-configuration.nix;
  pegasus-frontend-theme-configuration = ./theme-configuration.nix;
}
