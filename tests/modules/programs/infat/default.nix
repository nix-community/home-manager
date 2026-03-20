{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  infat-example-settings = ./example-settings.nix;
  infat-no-settings = ./no-settings.nix;
}
