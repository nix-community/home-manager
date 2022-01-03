{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.helix = {
      enable = true;

      settings = {
        theme = "base16";
        lsp.display-messages = true;
        keys.normal = {
          space.space = "file_picker";
          space.w = ":w";
          space.q = ":q";
        };
      };

      languages = [{
        name = "rust";
        auto-format = false;
      }];

      themes = {
        base16 = let
          transparent = "none";
          gray = "#665c54";
          dark-gray = "#3c3836";
          white = "#fbf1c7";
          black = "#282828";
          red = "#fb4934";
          green = "#b8bb26";
          yellow = "#fabd2f";
          orange = "#fe8019";
          blue = "#83a598";
          magenta = "#d3869b";
          cyan = "#8ec07c";
        in {
          "ui.menu" = transparent;
          "ui.menu.selected" = { modifiers = [ "reversed" ]; };
          "ui.linenr" = {
            fg = gray;
            bg = dark-gray;
          };
          "ui.popup" = { modifiers = [ "reversed" ]; };
          "ui.linenr.selected" = {
            fg = white;
            bg = black;
            modifiers = [ "bold" ];
          };
          "ui.selection" = {
            fg = black;
            bg = blue;
          };
          "ui.selection.primary" = { modifiers = [ "reversed" ]; };
          "comment" = { fg = gray; };
          "ui.statusline" = {
            fg = white;
            bg = dark-gray;
          };
          "ui.statusline.inactive" = {
            fg = dark-gray;
            bg = white;
          };
          "ui.help" = {
            fg = dark-gray;
            bg = white;
          };
          "ui.cursor" = { modifiers = [ "reversed" ]; };
          "variable" = red;
          "variable.builtin" = orange;
          "constant.numeric" = orange;
          "constant" = orange;
          "attributes" = yellow;
          "type" = yellow;
          "ui.cursor.match" = {
            fg = yellow;
            modifiers = [ "underlined" ];
          };
          "string" = green;
          "variable.other.member" = red;
          "constant.character.escape" = cyan;
          "function" = blue;
          "constructor" = blue;
          "special" = blue;
          "keyword" = magenta;
          "label" = magenta;
          "namespace" = blue;
          "diff.plus" = green;
          "diff.delta" = yellow;
          "diff.minus" = red;
          "diagnostic" = { modifiers = [ "underlined" ]; };
          "ui.gutter" = { bg = black; };
          "info" = blue;
          "hint" = dark-gray;
          "debug" = dark-gray;
          "warning" = yellow;
          "error" = red;
        };
      };
    };

    test.stubs.helix = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/helix/config.toml \
        ${./settings-expected.toml}
      assertFileContent \
        home-files/.config/helix/languages.toml \
        ${./languages-expected.toml}
      assertFileContent \
        home-files/.config/helix/themes/base16.toml \
        ${./theme-base16-expected.toml}
    '';
  };
}
