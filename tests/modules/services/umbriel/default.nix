{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  umbriel-empty-config = ./umbriel-empty-config.nix;
  umbriel-example-settings = ./umbriel-example-settings.nix;
  umbriel-package-null = ./umbriel-package-null.nix;
  umbriel-portal-only = ./umbriel-portal-only.nix;
  umbriel-systemd-requires-package = ./umbriel-systemd-requires-package.nix;
  umbriel-check-config-requires-package = ./umbriel-check-config-requires-package.nix;
}
