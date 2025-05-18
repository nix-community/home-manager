{ pkgs, ... }:

{
  time = "2025-04-28T03:17:15+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.kickoff'.

    Kickoff is a minimalist application launcher for Wayland designed to be fast
    and lightweight. It features a clean interface that appears at the center of
    the screen, fuzzy search functionality, and customizable appearance through
    theming. The module allows configuration of hotkeys, theme settings, and
    launch options.
  '';
}
