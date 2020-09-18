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

    nmt.script = ''
      assertFileExists home-files/.config/kak/kakrc
      assertFileContains home-files/.config/kak/kakrc \
        "add-highlighter global/ show-whitespaces -tab '4' -tabpad '5' -spc '2' -nbsp '3' -lf '1'"
    '';
  };
}
