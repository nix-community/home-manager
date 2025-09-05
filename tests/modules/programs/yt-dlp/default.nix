{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  yt-dlp-simple-config = ./yt-dlp-simple-config.nix;
  yt-dlp-extraConfig = ./yt-dlp-extraConfig.nix;
}
