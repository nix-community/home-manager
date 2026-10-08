{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  omniwm = ./omniwm.nix;
  omniwm-settings = ./omniwm-settings.nix;
}
