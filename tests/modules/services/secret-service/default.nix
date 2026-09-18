{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  secret-service-basic-configuration = ./basic-configuration.nix;
}
