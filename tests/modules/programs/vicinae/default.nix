{ lib, pkgs, ... }:
lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux) {
  vicinae-layer-home-file-disabled = ./layer-home-file-disabled.nix;
  vicinae-layer-home-file-redirected = ./layer-home-file-redirected.nix;
  vicinae-layer-override = ./layer-override.nix;
  vicinae-layer-file-disabled = ./layer-file-disabled.nix;
  vicinae-layer-empty = ./layer-empty.nix;
  vicinae-layer-colon-xdg = ./layer-colon-xdg.nix;
  vicinae-layer-colon-target = ./layer-colon-target.nix;
  vicinae-package-null = ./package-null.nix;
  vicinae-mutable-old-version = ./mutable-old-version.nix;
  vicinae-mutable-supported-version = ./mutable-supported-version.nix;
  vicinae-layer-custom = ./layer-custom.nix;

  vicinae-pre17-settings = ./pre17-settings.nix;
  vicinae-example-settings = ./example-settings.nix;
}
