{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  twmn-basic-configuration = ./basic-configuration.nix;
  twmn-modern-settings = ./modern-settings.nix;
  twmn-disabled = ./disabled.nix;
  twmn-migration-edge = ./migration-edge.nix;
  twmn-forced-settings = ./forced-settings.nix;
  twmn-enable-only-defaults = ./enable-only-defaults.nix;
  twmn-extra-config-defaults = ./extra-config-defaults.nix;
}
