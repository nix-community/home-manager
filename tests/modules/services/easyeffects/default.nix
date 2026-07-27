{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  easyeffects-service = ./service.nix;
  easyeffects-example-preset = ./example-preset.nix;
  easyeffects-null-presets = ./null-presets.nix;
  easyeffects-settings-old-version = ./settings-old-version.nix;
}
