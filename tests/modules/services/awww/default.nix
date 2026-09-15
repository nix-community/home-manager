{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  awww-default = ./awww-default.nix;
  awww-extraArgs = ./awww-extraArgs.nix;
  awww-null-package = ./awww-null-package.nix;
  awww-swww-package = ./awww-swww-package.nix;
}
