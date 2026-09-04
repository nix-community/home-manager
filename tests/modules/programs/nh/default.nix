{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  nh = ./darwin/config.nix;
  nh-clean-extra-args = ./darwin/clean-extra-args.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  nh = ./linux/config.nix;
})
