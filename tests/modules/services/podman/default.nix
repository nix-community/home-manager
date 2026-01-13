{ lib, pkgs, ... }:
{
  podman-configuration = ./configuration.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (import ./darwin/default.nix))
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))
