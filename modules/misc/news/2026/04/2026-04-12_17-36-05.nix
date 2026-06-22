{ pkgs, ... }:
{
  time = "2026-04-12T15:36:05+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.syshud`.

    A simple system status indicator for Wayland compositors.
  '';
}
