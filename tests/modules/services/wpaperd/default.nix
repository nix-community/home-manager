{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wpaperd-no-settings = ./wpaperd-no-settings.nix;
  wpaperd-example-settings = ./wpaperd-example-settings.nix;
}
