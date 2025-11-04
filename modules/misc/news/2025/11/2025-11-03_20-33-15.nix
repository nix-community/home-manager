{ pkgs, ... }:
{
  time = "2025-11-04T02:33:15+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new program is available: 'programs.vicinae'.

    Vicinae is a modern application launcher daemon for Linux with support for
    extensions, custom themes, and layer shell integration.

    The module provides:
    - Systemd service integration with automatic start support
    - Extension management with helpers for Vicinae and Raycast extensions
    - Theme configuration support
    - Declarative settings via 'programs.vicinae.settings'
    - Layer shell integration for Wayland compositors

    See the module options for more details on configuration.
  '';
}
