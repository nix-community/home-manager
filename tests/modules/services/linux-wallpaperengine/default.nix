{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  linux-wallpaperengine-basic-configuration = ./basic-configuration.nix;
  linux-wallpaperengine-null-options = ./null-options.nix;
}
