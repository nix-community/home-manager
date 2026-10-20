{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  jankyborders-basic-config = ./config.nix;
  jankyborders-restart-trigger-fallback = ./restart-trigger-fallback.nix;
}
