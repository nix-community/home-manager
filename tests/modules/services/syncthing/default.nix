{ lib, pkgs, ... }:
{
  syncthing-config-settings = ./config-settings.nix;
  syncthing-extra-options = ./extra-options.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))
