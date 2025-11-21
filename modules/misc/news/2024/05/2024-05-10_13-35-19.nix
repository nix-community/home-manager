{ pkgs, ... }:

{
  time = "2024-05-10T13:35:19+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.hyprpaper'.

    Hyprpaper is a blazing fast wallpaper utility for Hyprland with the
    ability to dynamically change wallpapers through sockets. It will work
    on all wlroots-based compositors, though. See
    https://github.com/hyprwm/hyprpaper for more.
  '';
}
