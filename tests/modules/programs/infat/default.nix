{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  infat-auto-activate-args = ./auto-activate-args.nix;
  infat-example-settings = ./example-settings.nix;
  infat-no-settings = ./no-settings.nix;
}
