{ pkgs, lib, ... }:

let

  snippetsDir = name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }/snippets"
    else
      ".config/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }snippets";

  globalSnippetsPath = name: "${snippetsDir name}/global.code-snippets";

  globalSnippetsExpectedContent = pkgs.writeText "global.code-snippet" ''
    {
      "fixme": {
        "body": [
          "fixme body in global user snippet"
        ],
        "description": "Insert a FIXME remark",
        "prefix": [
          "fixme"
        ]
      }
    }
  '';

  haskellSnippetsPath = name: "${snippetsDir name}/haskell.json";

  haskellSnippetsExpectedContent = pkgs.writeText "haskell.json" ''
    {
      "impl": {
        "body": [
          "impl body in user haskell snippet"
        ],
        "description": "Insert an implementation stub",
        "prefix": [
          "impl"
        ]
      }
    }
  '';

  snippets = {
    globalSnippets = {
      fixme = {
        prefix = [ "fixme" ];
        body = [ "fixme body in global user snippet" ];
        description = "Insert a FIXME remark";
      };
    };
    languageSnippets = {
      haskell = {
        impl = {
          prefix = [ "impl" ];
          body = [ "impl body in user haskell snippet" ];
          description = "Insert an implementation stub";
        };
      };
    };
  };

in {
  programs.vscode = {
    enable = true;
    package = pkgs.writeScriptBin "vscode" "" // {
      pname = "vscode";
      version = "1.75.0";
    };
    profiles = {
      default = snippets;
      test = snippets;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${globalSnippetsPath "default"}"
    assertFileContent "home-files/${
      globalSnippetsPath "default"
    }" "${globalSnippetsExpectedContent}"

    assertFileExists "home-files/${globalSnippetsPath "test"}"
    assertFileContent "home-files/${
      globalSnippetsPath "test"
    }" "${globalSnippetsExpectedContent}"

    assertFileExists "home-files/${haskellSnippetsPath "default"}"
    assertFileContent "home-files/${
      haskellSnippetsPath "default"
    }" "${haskellSnippetsExpectedContent}"

    assertFileExists "home-files/${haskellSnippetsPath "test"}"
    assertFileContent "home-files/${
      haskellSnippetsPath "test"
    }" "${haskellSnippetsExpectedContent}"
  '';
}
