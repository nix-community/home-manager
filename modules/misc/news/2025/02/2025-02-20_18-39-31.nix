{ pkgs, ... }:

{
  time = "2025-02-20T18:39:31+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.swayimg'.

    swayimg is a fully customizable and lightweight image viewer for
    Wayland based display servers.
    See https://github.com/artemsen/swayimg for more.
  '';
}
