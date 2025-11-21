{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpdscribble-basic-configuration = ./basic-configuration.nix;
}
