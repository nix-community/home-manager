{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hexchat-basic-configuration = ./basic-configuration.nix;
}
