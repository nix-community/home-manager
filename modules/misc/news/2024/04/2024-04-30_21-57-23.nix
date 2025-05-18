{ pkgs, ... }:

{
  time = "2024-04-30T21:57:23+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.conky'.

    Conky is a system monitor for X. Conky can display just about
    anything, either on your root desktop or in its own window. See
    https://conky.cc/ for more.
  '';
}
