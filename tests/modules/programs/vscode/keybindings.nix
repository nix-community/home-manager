# Test that keybindings.json is created correctly.
{ pkgs, lib, ... }:

let
  bindings = [
    {
      key = "ctrl+c";
      command = "editor.action.clipboardCopyAction";
      when = "textInputFocus && false";
    }
    {
      key = "ctrl+c";
      command = "deleteFile";
      when = "";
    }
    {
      key = "d";
      command = "deleteFile";
      when = "explorerViewletVisible";
    }
    {
      key = "ctrl+r";
      command = "run";
      args = { command = "echo file"; };
    }
  ];

  keybindingsPath = name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }keybindings.json"
    else
      ".config/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }keybindings.json";

  settingsPath = name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }settings.json"
    else
      ".config/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }settings.json";

  expectedKeybindings = pkgs.writeText "expected.json" ''
    [
      {
        "command": "editor.action.clipboardCopyAction",
        "key": "ctrl+c",
        "when": "textInputFocus && false"
      },
      {
        "command": "deleteFile",
        "key": "ctrl+c",
        "when": ""
      },
      {
        "command": "deleteFile",
        "key": "d",
        "when": "explorerViewletVisible"
      },
      {
        "args": {
          "command": "echo file"
        },
        "command": "run",
        "key": "ctrl+r"
      }
    ]
  '';

in {
  programs.vscode = {
    enable = true;
    profiles = {
      default.keybindings = bindings;
      test.keybindings = bindings;
    };
    package = pkgs.writeScriptBin "vscode" "" // {
      pname = "vscode";
      version = "1.75.0";
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${keybindingsPath "default"}"
    assertFileContent "home-files/${
      keybindingsPath "default"
    }" "${expectedKeybindings}"

    assertPathNotExists "home-files/${settingsPath "default"}"

    assertFileExists "home-files/${keybindingsPath "test"}"
    assertFileContent "home-files/${
      keybindingsPath "test"
    }" "${expectedKeybindings}"

    assertPathNotExists "home-files/${settingsPath "test"}"
  '';
}
