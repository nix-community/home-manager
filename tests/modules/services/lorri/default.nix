{ lib, pkgs, ... }:

(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  lorri-launchd-service = ./launchd-service.nix;
  lorri-launchd-extra-env-variables = ./launchd-extra-env-variables.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  lorri-systemd-extra-env-variables = ./systemd-extra-env-variables.nix;
})
