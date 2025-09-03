{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swayosd = ./swayosd.nix;
  swayosd-with-deprecated-options = ./deprecated-options.nix;
}
