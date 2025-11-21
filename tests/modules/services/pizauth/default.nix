{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux { pizauth-basic-config = ./basic-config.nix; }
