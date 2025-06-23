{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  imapnotify-launchd = ./launchd.nix;
}
