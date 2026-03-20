{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gnome-keyring-basic-service = ./basic-service.nix;
  gnome-keyring-custom-components = ./custom-components.nix;
}
