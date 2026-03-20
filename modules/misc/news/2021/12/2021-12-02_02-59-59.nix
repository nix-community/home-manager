{ config, ... }:

{
  time = "2021-12-02T02:59:59+00:00";
  condition = config.programs.waybar.enable;
  message = ''

    The Waybar module now allows defining modules directly under the 'settings'
    option instead of nesting the modules under 'settings.modules'.
    The Waybar module will also stop reporting errors about unused or misnamed
    modules.
  '';
}
