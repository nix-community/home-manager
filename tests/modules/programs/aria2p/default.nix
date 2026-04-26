{ lib, pkgs, ... }:

{
  aria2p-disabled = ./disabled.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  aria2p-settings = ./settings.nix;
}
