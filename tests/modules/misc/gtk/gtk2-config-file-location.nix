{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    gtk.enable = true;
    gtk.gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    test.stubs.dconf = { };

    nmt.script = ''
      assertFileExists home-files/.config/gtk-2.0/gtkrc
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
          'GTK2_RC_FILES=.*/\.config/gtk-2.0/gtkrc'
    '';
  };
}
