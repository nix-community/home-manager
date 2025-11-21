{ lib, pkgs, ... }:
{
  syncthing-extra-options = ./extra-options.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))
