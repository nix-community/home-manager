{ pkgs, ... }:
{
  time = "2026-05-05T14:14:28+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.gtklock'.

    Gtklock is GTK-based lockscreen for Wayland, based on gtkgreet.
  '';
}
