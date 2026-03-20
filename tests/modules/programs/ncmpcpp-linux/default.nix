{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  ncmpcpp-use-mpd-config = ./ncmpcpp-use-mpd-config.nix;
  ncmpcpp-issue-3560 = ./ncmpcpp-issue-3560.nix;
}
