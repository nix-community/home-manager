{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  gotify-desktop-url = ./gotify-desktop-url.nix;
  gotify-desktop-str-token = ./gotify-desktop-str-token.nix;
  gotify-desktop-command-token = ./gotify-desktop-command-token.nix;
  gotify-desktop-arbitrary-settings = ./gotify-desktop-arbitrary-settings.nix;
  gotify-desktop-empty-settings = ./gotify-desktop-empty-settings.nix;
  gotify-desktop-full-settings = ./gotify-desktop-full-settings.nix;
}
