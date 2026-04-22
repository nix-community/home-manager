{ pkgs, ... }:

{
  time = "2026-04-22T17:28:03+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'programs.rectangle'. Rectangle is an
    open-source window manager for macOS that allows you to move and
    resize windows with keyboard shortcuts or by snapping them to the
    edges of your screen.
  '';
}
