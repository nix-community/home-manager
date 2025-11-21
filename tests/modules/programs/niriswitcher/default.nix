{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  niriswitcher-program = ./niriswitcher.nix;
}
