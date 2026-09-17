{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  getmail-settings = ./settings.nix;
  getmail = ./getmail.nix;
}
