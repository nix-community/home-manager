{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  shpool-default-systemd = ./default-systemd.nix;
  shpool-systemd-disabled = ./systemd-disabled.nix;
}
