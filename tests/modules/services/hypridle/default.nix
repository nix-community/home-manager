{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hypridle-basic-configuration = ./basic-configuration.nix;
  hypridle-no-configuration = ./no-configuration.nix;
}
