{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  devilspie2-configuration = ./configuration.nix;
}
