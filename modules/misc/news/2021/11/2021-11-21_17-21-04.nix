{ config, ... }:

{
  time = "2021-11-21T17:21:04+00:00";
  condition = config.wayland.windowManager.sway.enable;
  message = ''

    A new module is available: 'wayland.windowManager.sway.swaynag'.
  '';
}
