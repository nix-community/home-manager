{ config, ... }:

{
  time = "2024-09-20T07:00:11+00:00";
  condition = config.programs.kitty.theme != null;
  message = ''

    The option 'programs.kitty.theme' has been deprecated, please use
    'programs.kitty.themeFile' instead.

    The 'programs.kitty.themeFile' option expects the file name of a
    theme from `kitty-themes`, without the `.conf` suffix. See
    <https://github.com/kovidgoyal/kitty-themes/tree/master/themes> for a
    list of themes.
  '';
}
