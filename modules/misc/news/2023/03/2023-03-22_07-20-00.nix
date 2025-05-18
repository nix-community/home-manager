{ pkgs, ... }:

{
  time = "2023-03-22T07:20:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.listenbrainz-mpd'.
  '';
}
