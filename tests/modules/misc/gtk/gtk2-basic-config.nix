{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    gtk = {
      enable = true;
      gtk2.extraConfig = "gtk-can-change-accels = 1";
    };

    test.stubs.dconf = { };

    nmt.script = ''
      assertFileExists home-files/.gtkrc-2.0
      assertFileContent home-files/.gtkrc-2.0 ${
        ./gtk-basic-config-expected.conf
      }
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
          'GTK2_RC_FILES=.*/.gtkrc-2.0'
    '';
  };
}
