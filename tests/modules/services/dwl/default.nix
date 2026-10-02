{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  dwl-systemd-enable = ./dwl-systemd-enable.nix;
  dwl-systemd-disable = ./dwl-systemd-disable.nix;
}
