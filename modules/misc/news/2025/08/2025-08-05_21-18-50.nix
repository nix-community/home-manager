{ pkgs, ... }:
{
  time = "2025-08-06T04:18:50+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new service is available: 'services.rescrobbled'.

    Rescrobbled is a music scrobbler daemon. It detects active media players
    running on D-Bus using MPRIS automatically updates "now playing" status, and
    scrobbles songs to Last.fm or ListenBrainz-compatible services as they play.
  '';
}
