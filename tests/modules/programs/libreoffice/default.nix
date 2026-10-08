{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  libreoffice-valid-configuration = ./valid.nix;
  libreoffice-basic-configuration = ./basic.nix;
  libreoffice-empty-configuration = ./empty.nix;
}
