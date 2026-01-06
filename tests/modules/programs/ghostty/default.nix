{ lib, pkgs, ... }:

{
  ghostty-empty-settings = ./empty-settings.nix;
  ghostty-example-settings = ./example-settings.nix;
  ghostty-example-theme = ./example-theme.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ghostty-systemd-service = ./systemd-service.nix;
}
