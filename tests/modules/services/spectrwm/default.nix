{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  spectrwm-simple-config = ./spectrwm-simple-config.nix;
}
