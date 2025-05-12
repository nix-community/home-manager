{ pkgs, ... }:

{
  time = "2024-05-10T11:48:34+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.hyprlock'.

    Hyprland's simple, yet multi-threaded and GPU-accelerated screen
    locking utility. See https://github.com/hyprwm/hyprlock for more.
  '';
}
