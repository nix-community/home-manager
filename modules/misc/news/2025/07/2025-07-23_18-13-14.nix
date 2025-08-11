{ pkgs, ... }:
{
  time = "2025-07-23T18:13:14+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.yofi'.

    Yofi is a minimalistic menu/launcher for Wayland compositors. It provides
    a fast and lightweight application launcher with search functionality
    and customizable appearance.
  '';
}
