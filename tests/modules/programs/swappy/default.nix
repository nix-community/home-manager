{ lib, pkgs, ... }:

(lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swappy-example-config = ./example-config.nix;
})
