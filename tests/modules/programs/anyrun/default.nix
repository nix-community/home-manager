{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  anyrun = ./basic-config.nix;
  anyrun-empty-css = ./empty-css.nix;
}
