{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./stubs.nix ];

  programs.kakoune = {
    enable = true;
    config.showWhitespace = {
      enable = true;
      lineFeed = ''"'';
      space = " ";
      nonBreakingSpace = "' '"; # backwards compat
      tab = "'";
      # tabStop = <default>
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/kak/kakrc
    assertFileContains home-files/.config/kak/kakrc \
      "add-highlighter global/ show-whitespaces -tab \"'\" -spc ' ' -nbsp ' ' -lf '\"'"
  '';
}
