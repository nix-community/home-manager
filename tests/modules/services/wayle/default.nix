{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wayle-basic-config = ./basic-config.nix;
  wayle-themes-config = ./themes-config.nix;
}
