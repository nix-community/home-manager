{ config, ... }:
{
  time = "2025-09-02T04:45:01+00:00";
  condition = config.wayland.windowManager.hyprland.enable;
  message = ''
    The 'wayland.windowManager.hyprland' module now supports submap configuration.

    Submaps allow you to create keybind contexts in Hyprland, useful for
    creating mode-based workflows like resize modes or application launch menus.
    Configure submaps using the new 'submaps' option:

    wayland.windowManager.hyprland.submaps.resize = {
      settings = {
        binde = [
          ", right, resizeactive, 10 0"
          ", left, resizeactive, -10 0"
          ", up, resizeactive, 0 -10"
          ", down, resizeactive, 0 10"
        ];
        bind = [
          ", escape, submap, reset"
        ];
      };
    };

    Learn more about submaps at:
    https://wiki.hypr.land/Configuring/Binds#submaps
  '';
}
