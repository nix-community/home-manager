{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  i3blocks-with-ordered-blocks = ./with-ordered-blocks.nix;
}
