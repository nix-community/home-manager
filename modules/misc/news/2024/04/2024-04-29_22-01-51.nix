{ pkgs, ... }:

{
  time = "2024-04-29T22:01:51+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.swaync'.

    SwayNotificationCenter is a simple notification daemon with a GTK GUI
    for notifications and the control center. See
    https://github.com/ErikReider/SwayNotificationCenter for more.
  '';
}
