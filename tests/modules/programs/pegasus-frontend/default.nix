{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pegasus-frontend-assets-configuration = ./assets-configuration.nix;
  pegasus-frontend-basic-configuration = ./basic-configuration.nix;
  pegasus-frontend-collections-configuration = ./collections-configuration.nix;
  pegasus-frontend-collectionMerge-configuration = ./collectionMerge-configuration.nix;
  pegasus-frontend-favorites-configuration = ./favorites-configuration.nix;
  pegasus-frontend-favorites-empty-configuration = ./favorites-empty-configuration.nix;
  pegasus-frontend-files-invalid-configuration = ./files-invalid-configuration.nix;
  pegasus-frontend-theme-configuration = ./theme-configuration.nix;
  pegasus-frontend-theme-settings-invalid-configuration = ./theme-settings-invalid-configuration.nix;
}
