{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  # assert that config is absent if options are not set
  niri-empty-config = ./niri-empty-config.nix;
  # assert that config is present and as expected if options are set
  niri-example-settings = ./niri-example-settings.nix;
}
