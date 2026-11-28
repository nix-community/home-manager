{ config, ... }:
{
  time = "2026-11-21T22:00:51+00:00";
  condition = config.wayland.windowManager.river.enable;
  message = ''
    The 'wayland.windowManager.river' module now targets river 0.4 and
    later, which no longer provides 'riverctl' and requires a separate
    window manager. Start the window manager from
    'wayland.windowManager.river.extraConfig'.

    The previous module, for river 0.3, is now available as
    'wayland.windowManager.river-classic'. If you used
    'wayland.windowManager.river.settings', rename your configuration to
    'wayland.windowManager.river-classic'.
  '';
}
