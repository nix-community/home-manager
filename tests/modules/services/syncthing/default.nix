{ lib, pkgs, ... }:
{
  syncthing-extra-options = ./extra-options.nix;
  syncthing-password-without-user = ./password-without-user.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))
