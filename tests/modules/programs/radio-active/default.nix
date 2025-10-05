{ lib, pkgs, ... }:

{
  radio-active-aliases = ./aliases.nix;
  radio-active-AppConfig = ./AppConfig.nix;
  radio-active-AppConfig_all = ./AppConfig_all.nix;
  radio-active-AppConfig_player_mpv = ./AppConfig_player_mpv.nix;
}
// lib.optionalAttrs (pkgs.stdenv.hostPlatform.isDarwin != true) {
  radio-active-AppConfig_player_vlc = ./AppConfig_player_vlc.nix;
}
