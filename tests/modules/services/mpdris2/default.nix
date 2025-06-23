{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpdris2-basic-configuration = ./basic-configuration.nix;
  mpdris2-with-password = ./with-password.nix;
}
