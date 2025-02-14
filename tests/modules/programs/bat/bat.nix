{
  programs.bat = {
    enable = true;

    config = {
      theme = "TwoDark";
      pager = "less -FR";
      map-syntax = [ "*.jenkinsfile:Groovy" "*.props:Java Properties" ];
      show-all = true;

      # False boolean options should not appear in the config
      lessopen = false;
    };

    themes.testtheme.src = builtins.toFile "testtheme.tmTheme" ''
      This is a test theme.
    '';

    syntaxes.testsyntax.src = builtins.toFile "testsyntax.sublime-syntax" ''
      This is a test syntax.
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/bat/config
    assertFileContent home-files/.config/bat/config ${
      builtins.toFile "bat.expected" ''
        --map-syntax='*.jenkinsfile:Groovy'
        --map-syntax='*.props:Java Properties'
        --pager='less -FR'
        --theme=TwoDark
        --show-all
      ''
    }

    assertFileExists home-files/.config/bat/themes/testtheme.tmTheme
    assertFileContent home-files/.config/bat/themes/testtheme.tmTheme ${
      builtins.toFile "bat.expected" ''
        This is a test theme.
      ''
    }

    assertFileExists home-files/.config/bat/syntaxes/testsyntax.sublime-syntax
    assertFileContent home-files/.config/bat/syntaxes/testsyntax.sublime-syntax ${
      builtins.toFile "bat.expected" ''
        This is a test syntax.
      ''
    }
  '';
}
