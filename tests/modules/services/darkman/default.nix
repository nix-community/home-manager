{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  darkman-basic-configuration = ./basic-configuration.nix;
  darkman-no-configuration = ./no-configuration.nix;
}
