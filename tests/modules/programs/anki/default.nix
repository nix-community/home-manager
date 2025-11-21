{ lib, pkgs, ... }:

# Anki is currently marked as broken on Darwin (2025/06/23)
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  anki-minimal-config = ./minimal-config.nix;
  anki-full-config = ./full-config.nix;
}
