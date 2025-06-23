{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  espanso-darwin-basic-configuration = ./basic-configuration.nix;
}
