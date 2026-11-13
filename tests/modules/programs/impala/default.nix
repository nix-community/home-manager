{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  impala-empty-config = ./empty-config.nix;
  impala-example-config = ./example-config.nix;
}
