{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mako-example-config = ./example-config.nix;
  mako-renamed-options = ./renamed-options.nix;
}
