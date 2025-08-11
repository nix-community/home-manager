{ pkgs, ... }:
{
  time = "2025-03-26T02:44:04+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.mpdscribble`

    Adds a module for mpdscribble, a music player daemon scrobbler.
  '';
}
