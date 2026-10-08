{ pkgs, ... }:
{
  time = "2026-07-29T11:54:36+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new option is available: 'programs.hyprtoolkit'

    hyprtoolkit is a GUI toolkit for developing applications that
    run natively on Wayland. It’s specifically made for Hyprland’s needs,
    but will generally run on any Wayland compositor that supports modern standards.

    See <https://wiki.hypr.land/Hypr-Ecosystem/hyprtoolkit/> for more options.
  '';
}
