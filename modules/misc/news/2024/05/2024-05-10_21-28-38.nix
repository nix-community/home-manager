{ pkgs, ... }:

{
  time = "2024-05-10T21:28:38+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.yambar'.

    Yambar is a lightweight and configurable status panel for X11 and
    Wayland, that goes to great lengths to be both CPU and battery
    efficient - polling is only done when absolutely necessary.

    See https://codeberg.org/dnkl/yambar for more.
  '';
}
