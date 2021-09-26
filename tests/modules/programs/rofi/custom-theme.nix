{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;

      theme = let inherit (config.lib.formats.rasi) mkLiteral;
      in {
        "@import" = "~/.cache/wal/colors-rofi-dark";

        "*" = {
          background-color = mkLiteral "#000000";
          foreground-color = mkLiteral "rgba ( 250, 251, 252, 100 % )";
          border-color = mkLiteral "#FFFFFF";
          width = 512;
        };

        "#inputbar" = { children = map mkLiteral [ "prompt" "entry" ]; };

        "#textbox-prompt-colon" = {
          expand = false;
          str = ":";
          margin = mkLiteral "0px 0.3em 0em 0em";
          text-color = mkLiteral "@foreground-color";
        };
      };
    };

    test.stubs.rofi = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/rofi/config.rasi \
        ${./custom-theme-config.rasi}
      assertFileContent \
        home-files/.local/share/rofi/themes/custom.rasi \
        ${./custom-theme.rasi}
    '';
  };
}
