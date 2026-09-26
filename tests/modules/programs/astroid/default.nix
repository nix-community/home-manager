{ lib, pkgs, ... }:
{
  astroid-disabled = ./disabled.nix;
  astroid-disabled-legacy = ./disabled-legacy.nix;
  astroid-native-only = ./native-only.nix;
  astroid-settings = ./settings.nix;
}
// import ./compatibility.nix { inherit lib; }
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  astroid-controls = ./controls.nix;
}
