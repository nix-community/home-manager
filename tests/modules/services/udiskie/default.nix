{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  udiskie-basic = ./basic.nix;
  udiskie-no-tray = ./no-tray.nix;
}
