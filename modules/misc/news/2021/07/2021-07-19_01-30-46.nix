{ pkgs, ... }:

{
  time = "2021-07-19T01:30:46+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.notify-osd'.
  '';
}
