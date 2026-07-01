{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  swayimg-empty-initLua = ./empty-initLua.nix;
  swayimg-example-initLua = ./example-initLua.nix;
  swayimg-path-initLua = ./path-initLua.nix;
}
