{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swaylock-current-default-disabled = import ./current-default-disabled.nix;
  swaylock-disabled = import ./disabled.nix;
  swaylock-settings = import ./settings.nix;
  swaylock-enabled = import ./enabled.nix;
  swaylock-legacy = import ./legacy.nix;
}
