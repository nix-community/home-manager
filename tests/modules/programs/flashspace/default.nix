{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  flashspace-settings-only = ./settings-only.nix;
  flashspace-profiles-only = ./profiles-only.nix;
  flashspace-full-config = ./full-config.nix;
}
