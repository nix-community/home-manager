{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wpaperd-example-settings = ./wpaperd-example-settings.nix;
}
