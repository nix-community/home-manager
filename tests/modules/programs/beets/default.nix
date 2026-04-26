{ lib, pkgs, ... }:

{
  beets-current-disable-default = ./current-disable-default.nix;
  beets-legacy-enable-default = ./legacy-enable-default.nix;
  beets-mpdupdate = ./mpdupdate.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  beets-mpdstats = ./mpdstats.nix;
  beets-mpdstats-external = ./mpdstats-external.nix;
}
