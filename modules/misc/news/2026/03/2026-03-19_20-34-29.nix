{ config, pkgs, ... }:
{
  time = "2026-03-20T02:34:29+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    A new module is available: 'services.wayle'.

    Wayle is a fast, configurable desktop environment shell for Wayland
    compositors. Built in Rust with Relm4 and focused on performance,
    modularity, and a great user experience. A successor to HyprPanel without
    the pain or dependency on Hyprland.
  '';
}
