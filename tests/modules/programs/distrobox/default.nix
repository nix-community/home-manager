{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  distrobox-example-config = ./example-config.nix;
  distrobox-no-asserts = ./no-asserts.nix;
  distrobox-assert-package-systemd-unit = ./assert-package-systemd-unit.nix;
  distrobox-assert-containers-systemd-unit = ./assert-containers-systemd-unit.nix;
}
