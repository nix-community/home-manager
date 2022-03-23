{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-cursor-blink = false;
        gtk-recent-files-limit = 20;
      };
    };

    test.stubs.dconf = { };

    nmt.script = ''
      assertFileExists home-files/.config/gtk-3.0/settings.ini

      assertFileContent home-files/.config/gtk-3.0/settings.ini \
        ${./gtk3-basic-settings-expected.ini}
    '';
  };
}
