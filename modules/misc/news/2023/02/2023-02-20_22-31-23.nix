{ pkgs, ... }:

{
  time = "2023-02-20T22:31:23+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.mpd-mpris'.
  '';
}
