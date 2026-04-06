{ lib, pkgs, ... }:
{
  aria2-disabled = ./disabled.nix;
  aria2-settings = ./settings.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  aria2-systemd = ./systemd.nix;
}
