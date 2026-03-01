{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  lorri-launchd-service = ./launchd-service.nix;
}
