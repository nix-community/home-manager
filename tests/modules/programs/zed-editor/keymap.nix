# Test custom keymap functionality
{ config, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userKeymaps = [
      { bindings = { up = "menu::SelectPrev"; }; }
      {
        context = "Editor";
        bindings = { escape = "editor::Cancel"; };
      }
    ];
  };

  nmt.script = let
    expectedContent = builtins.toFile "expected.json" ''
      [
        {
          "bindings": {
            "up": "menu::SelectPrev"
          }
        },
        {
          "bindings": {
            "escape": "editor::Cancel"
          },
          "context": "Editor"
        }
      ]
    '';

    keymapPath = ".config/zed/keymap.json";
  in ''
    assertFileExists "home-files/${keymapPath}"
    assertFileContent "home-files/${keymapPath}" "${expectedContent}"
  '';
}
