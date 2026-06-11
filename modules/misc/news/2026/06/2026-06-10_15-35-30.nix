{ config, ... }:
{
  time = "2026-06-10T15:35:30+00:00";
  condition = config.qt.enable;
  message = ''
    The value `gtk` for `qt.platformTheme.name` is no longer rewritten to
    `gtk2` when setting the `QT_QPA_PLATFORMTHEME` session variable. It is
    now emitted as `gtk3`, selecting Qt's built-in GTK platform theme plugin,
    and no longer installs the `qtstyleplugins` and `qt6gtk2`
    packages.

    If you relied on the previous behavior, set
    `qt.platformTheme.name = "gtk2"` explicitly, which sets
    `QT_QPA_PLATFORMTHEME=gtk2` and installs the `qtstyleplugins` and
    `qt6gtk2` packages providing that platform theme.
  '';
}
