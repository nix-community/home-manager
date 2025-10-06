{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  am2rlauncher-settings = ./settings.nix;
}
