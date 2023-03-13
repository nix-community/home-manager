{ pkgs, ... }:

let

  snippetsDir = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/Code/User/snippets"
  else
    ".config/Code/User/snippets";

  globalSnippetsPath = "${snippetsDir}/global.code-snippets";

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

  haskellSnippetsPath = "${snippetsDir}/haskell.json";

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

in {
  programs.vscode = {
    enable = true;
    package = pkgs.writeScriptBin "vscode" "" // { pname = "vscode"; };
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

  nmt.script = ''
    assertFileExists "home-files/${globalSnippetsPath}"
    assertFileContent "home-files/${globalSnippetsPath}" "${globalSnippetsExpectedContent}"

    assertFileExists "home-files/${haskellSnippetsPath}"
    assertFileContent "home-files/${haskellSnippetsPath}" "${haskellSnippetsExpectedContent}"
  '';
}
