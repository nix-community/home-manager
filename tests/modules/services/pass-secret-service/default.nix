{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pass-secret-service-default-configuration = ./default-configuration.nix;
  pass-secret-service-old-default-path = ./old-default-path.nix;
  pass-secret-service-old-default-empty-settings = ./old-default-empty-settings.nix;
  pass-secret-service-old-default-explicit-legacy-path = ./old-default-explicit-legacy-path.nix;
  pass-secret-service-old-default-partial-settings = ./old-default-partial-settings.nix;
  pass-secret-service-nondefault-path = ./nondefault-path.nix;
  pass-secret-service-basic-configuration = ./basic-configuration.nix;
}
