{ lib, pkgs, ... }:
{
  vicinae-layer-colon-target = ./layer-colon-target.nix;
  vicinae-layer-colon-xdg = ./layer-colon-xdg.nix;
  vicinae-layer-custom = ./layer-custom.nix;
  vicinae-layer-empty = ./layer-empty.nix;
  vicinae-mutable-old-version = ./mutable-old-version.nix;
  vicinae-mutable-supported-version = ./mutable-supported-version.nix;
  vicinae-package-null = ./package-null.nix;
  vicinae-unsupported-version = ./unsupported-version.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (import ./darwin/default.nix))
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))
