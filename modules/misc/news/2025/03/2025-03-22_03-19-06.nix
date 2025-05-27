{ pkgs, ... }:

{
  time = "2025-03-22T03:19:06+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'services.jankyborders'.

    JankyBorders adds customizable borders to macOS application windows. It provides
    features like adjustable border width, color, radius, and window title display.
    This module is particularly useful for improving window visibility when using a
    tiling window manager on macOS.
  '';
}
