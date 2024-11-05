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

      syntaxes.testsyntax = ''
        This is a test syntax.
      '';
    };

    test.stubs.bat = { };

    test.asserts.warnings.enable = true;
    test.asserts.warnings.expected = [
      ''
        Using programs.bat.themes as a string option is deprecated and will be
        removed in the future. Please change to using it as an attribute set
        instead.
      ''
      ''
        Using programs.bat.syntaxes as a string option is deprecated and will be
        removed in the future. Please change to using it as an attribute set
        instead.
      ''
    ];

    nmt.script = ''
      assertFileExists home-files/.config/bat/config
      assertFileContent home-files/.config/bat/config ${
        pkgs.writeText "bat.expected" ''
          --map-syntax='*.jenkinsfile:Groovy'
          --map-syntax='*.props:Java Properties'
          --pager='less -FR'
          --theme=TwoDark
        ''
      }

      assertFileExists home-files/.config/bat/themes/testtheme.tmTheme
      assertFileContent home-files/.config/bat/themes/testtheme.tmTheme ${
        pkgs.writeText "bat.expected" ''
          This is a test theme.
        ''
      }

      assertFileExists home-files/.config/bat/syntaxes/testsyntax.sublime-syntax
      assertFileContent home-files/.config/bat/syntaxes/testsyntax.sublime-syntax ${
        pkgs.writeText "bat.expected" ''
          This is a test syntax.
        ''
      }
    '';
  };
}
