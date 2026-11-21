{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  river-configuration = ./configuration.nix;
  river-no-systemd = ./no-systemd.nix;
}
