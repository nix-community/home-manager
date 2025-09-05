{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  fnott-example-settings = ./example-settings.nix;
  fnott-systemd-user-service = ./systemd-user-service.nix;
}
