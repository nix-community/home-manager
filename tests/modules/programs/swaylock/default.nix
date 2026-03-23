{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swaylock-disabled = import ./disabled.nix;
  swaylock-settings = import ./settings.nix;
  swaylock-enabled = import ./enabled.nix;
  swaylock-legacy = import ./legacy.nix;
}
