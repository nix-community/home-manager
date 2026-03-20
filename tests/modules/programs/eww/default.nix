{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  eww-basic-config = ./basic-config.nix;
  eww-null-config = ./null-config.nix;
}
