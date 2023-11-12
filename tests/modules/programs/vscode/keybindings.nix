# Test that keybindings.json is created correctly.
{ pkgs, ... }:

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

  keybindingsPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/Code/User/keybindings.json"
  else
    ".config/Code/User/keybindings.json";

  settingsPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/Code/User/settings.json"
  else
    ".config/Code/User/settings.json";

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
    keybindings = bindings;
    package = pkgs.writeScriptBin "vscode" "" // { pname = "vscode"; };
  };

  nmt.script = ''
    assertFileExists "home-files/${keybindingsPath}"
    assertFileContent "home-files/${keybindingsPath}" "${expectedKeybindings}"

    assertPathNotExists "home-files/${settingsPath}"
  '';
}
