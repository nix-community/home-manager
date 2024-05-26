# Test custom keymap functionality
{ pkgs, ...}:

let
  binds = [
    {
      bindings = {
        up = "menu::SelectPrev";
      };
    }
    {
      context = "Editor";
      bindings = {
        escape = "editor::Cancel";
      };
    }
  ];

  expectedContent = pkgs.writeText "expected.json" ''
    [
      {
        "bindings": {
          "up": "menu::SelectPrev",
        }
      },
      {
        "context": "Editor",
        "bindings": {
          "escape": "editor::Cancel"
        }
      }
    ]
  '';

  keymapPath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/zed/keymap.json"
  else
    ".config/zed/keymap.json";
in
{
  programs.zed-editor = {
    enable = true;
    userKeymaps = binds;
    package = pkgs.writeScriptBin "zed" "" // { pname = "zed-editor"; };
  };

  nmt.script = ''
    assertFileExists "home-files/${keymapPath}"
    assertFileContent "home-files/${keymapPath}" "${expectedContent}"
  '';
}