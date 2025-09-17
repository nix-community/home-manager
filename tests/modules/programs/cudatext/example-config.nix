{ pkgs, ... }:

{
  programs.cudatext = {
    enable = true;
    userSettings = {
      numbers_style = 2;
      numbers_center = false;
      numbers_for_carets = true;
    };

    hotkeys = {
      "2823" = {
        name = "code tree: clear filter";
        s1 = [ "Home" ];
      };

      "153" = {
        name = "delete char right (delete)";
        s1 = [ "End" ];
      };

      "655465" = {
        name = "caret to line end";
        s1 = [ ];
      };

      "116" = {
        name = "column select: page up";
        s1 = [ ];
      };

      "655464" = {
        name = "caret to line begin";
        s1 = [ ];
      };
    };

    lexerSettings = {
      C = {
        numbers_style = 2;
      };
      Python = {
        numbers_style = 1;
        numbers_center = false;
      };
      Rust = {
        numbers_style = 2;
        numbers_center = false;
        numbers_for_carets = true;
      };
    };

    lexerHotkeys = {
      C = {
        "153" = {
          name = "delete char right (delete)";
          s1 = [ "End" ];
        };

        "655465" = {
          name = "caret to line end";
          s1 = [ ];
        };
      };

      Python = {
        "2823" = {
          name = "code tree: clear filter";
          s1 = [ "Home" ];
        };

        "655464" = {
          name = "caret to line begin";
          s1 = [ ];
        };
      };
    };
  };

  nmt.script =
    let
      settingsPath =
        if pkgs.stdenv.isDarwin then
          "home-files/Library/Application Support/CudaText/settings"
        else
          "home-files/.config/cudatext/settings";
    in
    ''
      assertFileExists "${settingsPath}/user.json"
      assertFileExists "${settingsPath}/keys.json"

      assertFileExists "${settingsPath}/lexer C.json"
      assertFileExists "${settingsPath}/lexer Python.json"
      assertFileExists "${settingsPath}/lexer Rust.json"

      assertFileExists "${settingsPath}/keys lexer C.json"
      assertFileExists "${settingsPath}/keys lexer Python.json"



      assertFileContent "${settingsPath}/user.json" ${./user.json}
      assertFileContent "${settingsPath}/keys.json" ${./keys.json}

      assertFileContent "${settingsPath}/lexer C.json" ${./lexerC.json}
      assertFileContent "${settingsPath}/lexer Python.json" ${./lexerPython.json}
      assertFileContent "${settingsPath}/lexer Rust.json" ${./lexerRust.json}

      assertFileContent "${settingsPath}/keys lexer C.json" ${./keysLexerC.json}
      assertFileContent "${settingsPath}/keys lexer Python.json" ${./keysLexerPython.json}
    '';
}
