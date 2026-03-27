{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  aria2p-disabled = ./disabled.nix;
  aria2p-settings = ./settings.nix;
}
