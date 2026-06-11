{
  config,
  lib,
  ...
}:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userKeymaps = [
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
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      # For some reason, the preexisting keymaps is an empty file
      preexistingKeymaps = builtins.toFile "preexisting.json" "";

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
    in
    config.lib.test.runMutableConfigTest {
      files.${keymapPath} = preexistingKeymaps;
      expected.${keymapPath} = expectedContent;
    };
}
