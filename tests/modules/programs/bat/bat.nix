{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bat = {
      enable = true;

      config = {
        theme = "TwoDark";
        pager = "less -FR";
        map-syntax = [ "*.jenkinsfile:Groovy" "*.props:Java Properties" ];
      };

      themes.testtheme = ''
        This is a test theme.
      '';
    };

    test.stubs.bat = { };

    nmt.script = ''
      assertFileExists home-files/.config/bat/config
      assertFileContent home-files/.config/bat/config ${
        pkgs.writeText "bat.expected" ''
          --map-syntax='*.jenkinsfile:Groovy'
          --map-syntax='*.props:Java Properties'
          --pager='less -FR'
          --theme='TwoDark'
        ''
      }

      assertFileExists home-files/.config/bat/themes/testtheme.tmTheme
      assertFileContent home-files/.config/bat/themes/testtheme.tmTheme ${
        pkgs.writeText "bat.expected" ''
          This is a test theme.
        ''
      }
    '';
  };
}
