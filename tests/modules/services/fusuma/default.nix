{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  fusuma-example-settings = ./settings.nix;
  fusuma-systemd-user-service = ./service.nix;
}
