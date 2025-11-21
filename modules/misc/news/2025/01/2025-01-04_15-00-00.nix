{ pkgs, ... }:

{
  time = "2025-01-04T15:00:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'wayland.windowManager.wayfire'.

    Wayfire is a 3D Wayland compositor, inspired by Compiz and based on
    wlroots. It aims to create a customizable, extendable and lightweight
    environment without sacrificing its appearance.

    This Home Manager module allows you to configure both wayfire itself,
    as well as wf-shell.
  '';
}
