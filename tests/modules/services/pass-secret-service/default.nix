{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pass-secret-service-default-configuration = ./default-configuration.nix;
  pass-secret-service-basic-configuration = ./basic-configuration.nix;
}
