{ config, ... }:

{
  time = "2023-06-15T16:30:00+00:00";
  condition = config.qt.enable;
  message = ''

    Qt module now supports new platform themes and styles, and has partial
    support for Qt6. For example, you can now use:

    - `qt.platformTheme = "kde"`: set a theme using Plasma. You can
    configure it by setting `~/.config/kdeglobals` file;
    - `qt.platformTheme = "qtct"`: set a theme using qt5ct/qt6ct. You
    can control it by using the `qt5ct` and `qt6ct` applications;
    - `qt.style.name = "kvantum"`: override the style by using themes
    written in SVG. Supports many popular themes.
  '';
}
