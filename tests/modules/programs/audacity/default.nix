{ lib, pkgs, ... }:
{
  audacity-with-settings = ./with-settings.nix;
  audacity-with-macros = ./with-macros.nix;
  audacity-null-package-empty-settings = ./null-package-empty.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  audacity-v4-settings = ./v4-settings.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  audacity-v4-darwin = ./v4-darwin.nix;
}
