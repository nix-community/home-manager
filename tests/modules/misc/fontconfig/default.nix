{ lib, pkgs, ... }:
{
  fontconfig-no-font-package = ./no-font-package.nix;
  fontconfig-single-font-package = ./single-font-package.nix;
  fontconfig-multiple-font-packages = ./multiple-font-packages.nix;

  fontconfig-default-rendering = ./default-rendering.nix;
  fontconfig-custom-rendering = ./custom-rendering.nix;
  fontconfig-extra-config-files = ./extra-config-files.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  fontconfig-mutable-placeholder = ./mutable-placeholder.nix;
}
