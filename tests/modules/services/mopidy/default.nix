{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mopidy-basic-configuration = ./basic-configuration.nix;
  mopidy-scan = ./mopidy-scan.nix;
}
