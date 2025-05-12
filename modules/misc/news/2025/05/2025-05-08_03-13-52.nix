{ pkgs, ... }:

{
  time = "2025-05-08T03:13:52+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.lutris'.

    Lutris is an open-source gaming platform for Linux. It simplifies the
    installation and management of games from various sources, including Steam,
    GOG, Epic Games Store, Ubisoft Connect, and more. The module allows you to
    configure Lutris settings including runner options, system preferences, and
    interface customization.
  '';
}
