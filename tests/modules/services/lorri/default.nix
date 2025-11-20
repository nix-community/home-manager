{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  lorri-launchd-service = ./launchd-service.nix;
  lorri-launchd-extra-env-variables = ./launchd-extra-env-variables.nix;
}
