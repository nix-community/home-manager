{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ashell-basic-toml = ./basic-toml-config.nix;
  ashell-basic-yaml = ./basic-yaml-config.nix;
  ashell-empty-settings = ./empty-settings.nix;
  ashell-systemd-service = ./systemd-service.nix;
}
