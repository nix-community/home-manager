{ pkgs, ... }:

{
  time = "2025-04-10T08:10:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.way-displays'.

    A service to automatically configure your displays on wlroots-based
    wayland compositors.
  '';
}
