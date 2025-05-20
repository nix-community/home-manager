{ pkgs, ... }:
{
  time = "2025-03-25T20:44:04-06:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.mpdscribble`

    Adds a module for mpdscribble, a music player daemon scrobbler.
  '';
}
