{ config, ... }:
{
  time = "2026-11-14T17:29:32+00:00";
  condition = config.programs.t3code.enable;
  message = ''
    The `programs.t3code` module now supports T3 environment themes.

    Set `programs.t3code.themes.<id>` to a JSON attribute set or a path to a
    theme file. Each entry is written to
    `~/.t3/userdata/themes/<id>.json` as a regular file during activation,
    replacing any symlink or file left by an earlier configuration.

    Set `programs.t3code.defaultTheme` to select one of the defined themes. The
    token T3 uses to track when a default theme was last applied is derived from
    the selected theme's content, so it changes when the theme changes.
  '';
}
