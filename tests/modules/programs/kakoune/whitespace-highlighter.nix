{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.kakoune = {
      enable = true;
      config.showWhitespace = {
        enable = true;
        lineFeed = "1";
        space = "2";
        nonBreakingSpace = "3";
        tab = "4";
        tabStop = "5";
      };
    };

    nmt.script = let
      lineStart =
        "^add-highlighter\\s\\+global\\/\\?\\s\\+show-whitespaces\\s\\+"
        + "\\(-\\w\\+\\s\\+.\\s\\+\\)*";
    in ''
      assertFileExists home-files/.config/kak/kakrc
      assertFileRegex home-files/.config/kak/kakrc '${lineStart}-lf\s\+1\b'
      assertFileRegex home-files/.config/kak/kakrc '${lineStart}-spc\s\+2\b'
      assertFileRegex home-files/.config/kak/kakrc '${lineStart}-nbsp\s\+3\b'
      assertFileRegex home-files/.config/kak/kakrc '${lineStart}-tab\s\+4\b'
      assertFileRegex home-files/.config/kak/kakrc '${lineStart}-tabpad\s\+5\b'
    '';
  };
}
