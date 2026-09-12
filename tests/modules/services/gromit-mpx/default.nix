{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gromit-mpx-default-configuration = ./default-configuration.nix;
  gromit-mpx-basic-configuration = ./basic-configuration.nix;
  gromit-mpx-extra-config = ./extra-config.nix;
  gromit-mpx-disabled = ./disabled.nix;
  gromit-mpx-whole-tree-force = ./whole-tree-force.nix;
}
