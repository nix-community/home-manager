{ config, ... }:

{
  time = "2023-12-10T08:43:02+00:00";
  condition = config.wayland.windowManager.hyprland.settings ? source;
  message = ''

    Entries in

      wayland.windowManager.hyprland.settings.source

    are now placed at the start of the configuration file. If you relied
    on the previous placement of the 'source' entries, please set

       wayland.windowManager.hyprland.sourceFirst = false

    to keep the previous behaviour.
  '';
}
