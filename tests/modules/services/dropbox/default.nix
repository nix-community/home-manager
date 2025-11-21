{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  dropbox-basic-configuration = ./basic-configuration.nix;
}
