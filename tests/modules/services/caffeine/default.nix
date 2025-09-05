{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  caffeine-basic-service = ./basic-service.nix;
}
