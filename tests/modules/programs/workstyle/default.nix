{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  workstyle-basic-configuration = ./basic-configuration.nix;
  workstyle-empty-configuration = ./empty-configuration.nix;
  workstyle-systemd-user-service = ./systemd-user-service.nix;
  workstyle-full-configuration = ./full-configuration.nix;
}
