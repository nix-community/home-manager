{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;
      width = 100;
      lines = 10;
      borderWidth = 1;
      rowHeight = 1;
      padding = 400;
      font = "Droid Sans Mono 14";
      scrollbar = true;
      terminal = "/some/path";
      separator = "solid";
      cycle = false;
      fullscren = true;
      colors = {
        window = {
          background = "argb:583a4c54";
          border = "argb:582a373e";
          separator = "#c3c6c8";
        };

        rows = {
          normal = {
            background = "argb:58455a64";
            foreground = "#fafbfc";
            backgroundAlt = "argb:58455a64";
            highlight = {
              background = "#00bcd4";
              foreground = "#fafbfc";
            };
          };
        };
      };
      window = {
        background = "background";
        border = "border";
        separator = "separator";
      };
      extraConfig = {
        modi = "drun,emoji,ssh";
        kb-primary-paste = "Control+V,Shift+Insert";
        kb-secondary-paste = "Control+v,Insert";
      };
    };

    nixpkgs.overlays =
      [ (self: super: { rofi = pkgs.writeScriptBin "dummy-rofi" ""; }) ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/rofi/config.rasi \
        ${./valid-config-expected.rasi}
    '';
  };
}
