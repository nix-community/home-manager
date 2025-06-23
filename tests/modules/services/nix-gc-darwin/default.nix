{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  nix-gc = ./basic.nix;
  darwin-nix-gc-interval-assertion = ./darwin-nix-gc-interval-assertion.nix;
}
