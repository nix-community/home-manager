{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  git-sync = ./basic.nix;
  git-sync-with-whitespace = ./whitespace.nix;
}
