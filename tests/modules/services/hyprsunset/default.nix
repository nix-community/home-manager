{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hyprsunset-basic-configuration = ./basic-configuration.nix;
  hyprsunset-no-configuration = ./no-configuration.nix;
  hyprsunset-transitions-deprecated = ./transitions-deprecated.nix;
}
