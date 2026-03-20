{ pkgs, ... }:
{
  time = "2025-05-16T20:29:26+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.ptyxis'.

    This module provides configuration for Ptyxis, a modern GNOME terminal
    emulator that offers contemporary features and seamless integration with
    the GNOME desktop environment.
  '';
}
