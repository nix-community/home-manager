{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  pipewire-configs = ./configs.nix;
  pipewire-empty = ./empty.nix;
  pipewire-scripts = ./scripts.nix;
}
