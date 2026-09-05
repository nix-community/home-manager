{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gromit-mpx-default-configuration = ./default-configuration.nix;
  gromit-mpx-basic-configuration = ./basic-configuration.nix;
  gromit-mpx-settings = ./settings.nix;
  gromit-mpx-legacy-opacity = ./legacy-opacity.nix;
  gromit-mpx-disabled = ./disabled.nix;
}
