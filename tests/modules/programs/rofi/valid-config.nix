{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;
      font = "Droid Sans Mono 14";
      terminal = "/some/path";
      separator = "solid";
      cycle = false;
      extraConfig = {
        modi = "drun,emoji,ssh";
        kb-primary-paste = "Control+V,Shift+Insert";
        kb-secondary-paste = "Control+v,Insert";
      };
    };

    test.stubs.rofi = { version = "1.7.0"; };

    nmt.script = ''
      assertFileContent \
        home-files/.config/rofi/config.rasi \
        ${./valid-config-expected.rasi}
    '';
  };
}
