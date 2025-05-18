{ pkgs, ... }:

{
  time = "2023-07-20T21:56:49+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'wayland.windowManager.hyprland'
  '';
}
