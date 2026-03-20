{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wlsunset-service = ./wlsunset-service.nix;
}
