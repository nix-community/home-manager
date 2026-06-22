{ config, ... }:
{
  time = "2026-04-17T14:17:31+00:00";
  condition = config.programs.kitty.enable;
  message = ''
    A new option 'programs.kitty.diffConfig' is available for configuring
    '$XDG_CONFIG_HOME/kitty/diff.conf'

    See https://sw.kovidgoyal.net/kitty/kittens/diff/
    for more documentation.
  '';
}
