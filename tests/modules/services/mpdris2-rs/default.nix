{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  mpdris2-rs-basic-configuration = ./basic-configuration.nix;
  mpdris2-rs-custom-notifications = ./custom-notifications.nix;
}
