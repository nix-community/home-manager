{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rofi-valid-config = ./valid-config.nix;
  rofi-basic-configuration = ./basic-configuration.nix;
  rofi-whole-settings-force = ./whole-settings-force.nix;
  rofi-whole-extra-config-force = ./whole-extra-config-force.nix;
  rofi-custom-theme = ./custom-theme.nix;
  rofi-config-with-deprecated-options = ./config-with-deprecated-options.nix;
}
