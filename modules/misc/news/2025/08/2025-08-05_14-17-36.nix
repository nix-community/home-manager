{ config, ... }:
{
  time = "2025-08-05T19:17:36+00:00";
  condition = config.fonts.fontconfig.enable;
  message = ''
    The 'fontconfig' module now supports font rendering configuration.

    New options have been added to control font appearance:
    - 'fontconfig.antialiasing' - Enable/disable font antialiasing
    - 'fontconfig.hinting' - Set hinting mode (none, slight, medium, full)
    - 'fontconfig.subpixelRendering' - Configure sub-pixel rendering (none, rgb, bgr, etc.)
  '';
}
