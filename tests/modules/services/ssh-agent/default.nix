{
  lib,
  pkgs,
  ...
}:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux))
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (import ./darwin))
