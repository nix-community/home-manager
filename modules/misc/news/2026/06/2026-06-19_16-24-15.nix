{ config, ... }:
{
  time = "2026-06-19T13:24:15+00:00";
  condition = config.programs.hyprland-qt-support.enable;
  message = ''
    A new module is available: `programs.hyprland-qt-support`.

    This module enables Hyprland Qt support — a Qt6 QML style provider for
    hypr* apps. It can be configured through the `settings` attribute.
  '';
}
