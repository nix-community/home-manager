{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  tomat-service = ./tomat.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  tomat-runs-under-launchd = ./darwin.nix;
}
