{ config, ... }:
{
  time = "2026-01-19T04:46:34+00:00";
  condition = config.gtk.enable && config.gtk.gtk2.enable;
  message = ''
    The `gtk2` module now respects `config.home.preferXdgDirectories` when installing your configuration.

    Previously, the GTK 2 configuration file was always installed to `~/.gtkrc-2.0`, regardless of your preference for XDG directories.
    Now, it will be installed to `${config.xdg.configHome}/gtk-2.0/gtkrc` if you have `config.home.preferXdgDirectories` set to `true`.
  '';
}
