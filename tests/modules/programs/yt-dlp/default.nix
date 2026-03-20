{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  yt-dlp-config = ./yt-dlp-config.nix;
}
