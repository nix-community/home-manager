{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wayfire-configuration = ./configuration.nix;
  wayfire-wf-shell = ./wf-shell.nix;
}
