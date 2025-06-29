{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  nh = ./darwin/config.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  nh = ./linux/config.nix;
})
