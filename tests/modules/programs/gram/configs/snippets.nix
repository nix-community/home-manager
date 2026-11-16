{ config, pkgs, ... }:

let
  inherit (pkgs) formats writeText;

  jsonFormat = formats.json { };

  cfg = config.programs.gram;

  expectedHtml = jsonFormat.generate "html.json" cfg.snippets.html;
  expectedJavascript = jsonFormat.generate "javascript.json" cfg.snippets.javascript;
  expectedFoobar = writeText "foobar.json" cfg.snippets."foobar.json";
in

{
  programs.gram = {
    enable = true;

    snippets = {
      html = {
        "Define doctype" = {
          prefix = "doctype";
          description = "Defines the document type";
          body = [
            "<!DOCTYPE>"
            "$1"
          ];
        };
      };
      javascript = {
        "Log to console" = {
          prefix = "log";
          description = "Logs to console";
          body = [
            ''console.info("Hello, ''${1:World}!")''
            "$0"
          ];
        };
      };
      "foobar.json" = ''
        This should be written as-is.
      '';
    };
  };

  nmt.script = ''
    snippetsDir=home-files/.config/gram/snippets

    assertFileExists $snippetsDir/html.json
    assertFileContent $snippetsDir/html.json ${expectedHtml}

    assertFileExists $snippetsDir/javascript.json
    assertFileContent $snippetsDir/javascript.json ${expectedJavascript}

    assertFileExists $snippetsDir/foobar.json
    assertFileContent $snippetsDir/foobar.json ${expectedFoobar}
  '';
}
