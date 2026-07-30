{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wbg-basic = ./basic.nix;
  wbg-stretch = ./stretch.nix;
  wbg-extra-args = ./extra-args.nix;
}
