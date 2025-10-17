{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wl-clip-persist-basic = ./wl-clip-persist-basic.nix;
  wl-clip-persist-advanced = ./wl-clip-persist-advanced.nix;
  wl-clip-persist-clipboard-both = ./wl-clip-persist-clipboard-both.nix;
}
