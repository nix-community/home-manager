{ pkgs, ... }:

{
  time = "2024-01-03T19:25:09+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'xdg.portal'.
  '';
}
