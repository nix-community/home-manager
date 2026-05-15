{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  sequoia-keystore-darwin = ./darwin.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  sequoia-keystore-linux = ./linux.nix;
})
