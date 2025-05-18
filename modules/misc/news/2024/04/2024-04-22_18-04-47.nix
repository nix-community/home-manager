{ pkgs, ... }:

{
  time = "2024-04-22T18:04:47+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.amberol'.

    Amberol is a music player with no delusions of grandeur. If you just
    want to play music available on your local system then Amberol is the
    music player you are looking for. See https://apps.gnome.org/Amberol/
    for more.
  '';
}
