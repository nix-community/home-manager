{
  config,
  lib,
  pkgs,
  ...
}:

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

  assertions =
    let
      settingsFilePath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/CudaText/settings"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/cudatext/settings";
      settingsFiles = lib.filterAttrs (
        name: _: lib.hasPrefix "${settingsFilePath}/" name
      ) config.home.file;
      cleanup = config.home.activation.cudatextImmutableSettings;
    in
    [
      {
        assertion = !config.programs.cudatext.mutableSettings;
        message = "cudatext example-config must default to immutable settings.";
      }
      {
        assertion = !(config.home.activation ? cudatextSettings);
        message = "cudatext example-config must not create mutable activation.";
      }
      {
        assertion = cleanup.after == [ "writeBoundary" ];
        message = "cudatext example-config cleanup must run after writeBoundary.";
      }
      {
        assertion = cleanup.before == [ "linkGeneration" ];
        message = "cudatext example-config cleanup must run before linkGeneration.";
      }
      {
        assertion = lib.all (
          file:
          file.enable
          && lib.hasInfix (lib.escapeShellArg file.target) cleanup.data
          && lib.hasInfix (lib.escapeShellArg (builtins.unsafeDiscardStringContext (toString file.source))) cleanup.data
        ) (builtins.attrValues settingsFiles);
        message = "cudatext example-config cleanup must use the configured file source.";
      }
    ];

  nmt.script =
    let
      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/CudaText/settings"
        else
          "home-files/.config/cudatext/settings";
    in
    ''
      assertFileContent "${settingsPath}/user.json" ${./user.json}
      assertFileContent "${settingsPath}/keys.json" ${./keys.json}

      assertFileContent "${settingsPath}/lexer C.json" ${./lexerC.json}
      assertFileContent "${settingsPath}/lexer Python.json" ${./lexerPython.json}
      assertFileContent "${settingsPath}/lexer Rust.json" ${./lexerRust.json}

      assertFileContent "${settingsPath}/keys lexer C.json" ${./keysLexerC.json}
      assertFileContent "${settingsPath}/keys lexer Python.json" ${./keysLexerPython.json}
    '';
}
