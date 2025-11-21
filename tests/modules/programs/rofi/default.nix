{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rofi-valid-config = ./valid-config.nix;
  rofi-custom-theme = ./custom-theme.nix;
  rofi-config-with-deprecated-options = ./config-with-deprecated-options.nix;
}
