{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  foliate-basic-theme = ./basic-theme.nix;
}
