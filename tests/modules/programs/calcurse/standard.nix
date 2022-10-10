{ config, lib, pkgs, ... }:

with lib;

let
  conf = builtins.toFile "settings-expected" ''
    appearance.calendarview=monthly
    appearance.compactpanels=no
    appearance.defaultpanel=calendar'';

  keys = builtins.toFile "keys" ''
    add-item  a A
    del-item  g'';
in {
  config = {
    programs.calcurse = {
      enable = true;

      settings = {
        appearance = {
          calendarview = "monthly";
          compactpanels = false;
          defaultpanel = "calendar";
        };
      };

      keys = {
        add-item = [ "a" "A" ];
        del-item = "g";
      };
    };

    test.stubs.calcurse = { };

    nmt.script = ''
      assertFileExists home-files/.config/calcurse/conf
      assertFileContent home-files/.config/calcurse/conf ${conf}

      assertFileExists home-files/.config/calcurse/keys
      assertFileContent home-files/.config/calcurse/keys ${keys}
    '';
  };
}
