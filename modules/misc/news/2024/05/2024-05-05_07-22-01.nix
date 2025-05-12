{ pkgs, ... }:

{
  time = "2024-05-05T07:22:01+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.hypridle'.

    Hypridle is a program that monitors user activity and runs commands
    when idle or active. See https://github.com/hyprwm/hypridle for more.
  '';
}
