{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  activitywatch-basic-setup = ./basic-setup.nix;
  activitywatch-empty-server-settings = ./empty-server-settings.nix;
}
