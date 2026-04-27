{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  imapgoose-service-darwin = ./darwin-configuration.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  imapgoose-service-linux = ./linux-configuration.nix;
})
