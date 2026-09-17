{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpdris2-basic-configuration = ./basic-configuration.nix;
  mpdris2-with-password = ./with-password.nix;
  mpdris2-legacy-path = ./legacy-path.nix;
  mpdris2-disabled = ./disabled.nix;
  mpdris2-native-settings = ./native-settings.nix;
  mpdris2-settings = ./settings.nix;
}
