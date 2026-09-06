{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  nh = ./darwin/config.nix;
  nh-clean-extra-args = ./darwin/clean-extra-args.nix;
  nh-clean-extra-args-spaces = ./darwin/clean-extra-args-spaces.nix;
  nh-clean-extra-args-string = ./darwin/clean-extra-args-string.nix;
  nh-clean-extra-args-empty = ./darwin/clean-extra-args-empty.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  nh = ./linux/config.nix;
  nh-clean-extra-args = ./linux/clean-extra-args.nix;
  nh-clean-extra-args-spaces = ./linux/clean-extra-args-spaces.nix;
  nh-clean-extra-args-string = ./linux/clean-extra-args-string.nix;
  nh-clean-extra-args-empty = ./linux/clean-extra-args-empty.nix;
})
