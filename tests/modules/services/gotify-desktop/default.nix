{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gotify-dekstop-str-token = ./gotify-dekstop-str-token.nix;
  gotify-dekstop-command-token = ./gotify-dekstop-command-token.nix;
  gotify-dekstop-settings = ./gotify-dekstop-settings.nix;
}
