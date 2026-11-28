{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  neverest-service-darwin = ./darwin-configuration.nix;
  neverest-exec-darwin = ./exec-configuration.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  neverest-service-linux = ./linux-configuration.nix;
  neverest-exec-linux = ./exec-configuration.nix;
})
