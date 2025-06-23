{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  remmina-default-config = ./default-config.nix;
  remmina-basic-config = ./basic-config.nix;
}
