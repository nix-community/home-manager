{ pkgs, ... }:
{
  time = "2025-09-13T22:00:10+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module, `wayland.desktopManager.cosmic`, is now available for
    configuring the COSMIC desktop environment. This module allows you to
    manage COSMIC components, configuration files, and reset the desktop
    to a known state.
  '';
}
