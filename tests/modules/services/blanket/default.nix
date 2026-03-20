{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  blanket-basic-configuration = ./basic-configuration.nix;
}
