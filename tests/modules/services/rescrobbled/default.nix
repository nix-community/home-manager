{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rescrobbled-basic-config = ./basic-config.nix;
}
