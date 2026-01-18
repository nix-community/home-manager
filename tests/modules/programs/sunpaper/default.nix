{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  sunpaper-example-config = ./example-config.nix;
  sunpaper-disabled = ./disabled.nix;
}
