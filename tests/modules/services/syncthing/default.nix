{ lib, pkgs, ... }:
{
  syncthing-extra-options = ./extra-options.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  syncthing-darwin-init-run-at-load = ./darwin-init-run-at-load.nix;
})
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))
