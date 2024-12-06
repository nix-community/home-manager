{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;
      font = "Droid Sans Mono 14";
      terminal = "/some/path";
      cycle = false;
      modes = [
        "drun"
        "emoji"
        "ssh"
        {
          name = "foo";
          path = "bar";
        }
      ];
      window = {
        background = "background";
        border = "border";
        separator = "separator";
      };
      extraConfig = {
        kb-primary-paste = "Control+V,Shift+Insert";
        kb-secondary-paste = "Control+v,Insert";
      };
    };

    test.stubs.rofi = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/rofi/config.rasi \
        ${./valid-config-expected.rasi}
    '';
  };
}
