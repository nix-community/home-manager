{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  noctalia-empty-config = ./empty-config.nix;
  noctalia-example-config = ./example-config.nix;
  noctalia-custom-palette = ./custom-palette.nix;
  noctalia-systemd-enabled = ./systemd-enabled.nix;
}
