{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  imapgoose-service-darwin = ./darwin-configuration.nix;
  imapgoose-exec-darwin = ./exec-configuration.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  imapgoose-service-linux = ./linux-configuration.nix;
  imapgoose-exec-linux = ./exec-configuration.nix;
})
