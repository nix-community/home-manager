{ pkgs, ... }:
{
  time = "2025-07-10T19:23:15+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new service is available: 'services.hyprshell'.

    Hyprshell is a modern GTK4-based window switcher and application launcher
    designed specifically for Hyprland. It provides a clean interface for
    switching between windows and launching applications.
  '';
}
