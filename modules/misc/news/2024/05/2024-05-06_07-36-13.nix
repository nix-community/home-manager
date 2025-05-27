{ pkgs, ... }:

{
  time = "2024-05-06T07:36:13+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.gnome-shell'.

    GNOME Shell is the graphical shell of the GNOME desktop environment.
    It provides basic functions like launching applications and switching
    between windows, and is also a widget engine.
  '';
}
