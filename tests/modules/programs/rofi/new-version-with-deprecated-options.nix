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
      scrollbar = true;
      separator = "solid";
      fullscreen = true;
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
    };

    test.stubs.rofi = { version = "1.7.0"; };

    test.asserts.assertions.expected = let

    in map (option: ''
      Option `programs.rofi.${option}` was removed from upstream on version '1.7.0'.

      Use `programs.rofi.theme` or downgrade rofi using `programs.rofi.package` instead.
    '') [
      "width"
      "lines"
      "borderWidth"
      "rowHeight"
      "padding"
      "separator"
      "scrollbar"
      "fullscreen"
      "colors"
    ];
  };
}
