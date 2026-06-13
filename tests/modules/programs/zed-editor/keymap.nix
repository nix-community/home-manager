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
      preexistingKeymaps = builtins.toFile "preexisting.json" ''
        [
          // Things changed interactively
          {
            "bindings": {
              "down": "menu::SelectNext"
            }
          },
          {
            "bindings": {
              "down": "select"
            },
            "context": "Terminal"
          },

          /* Manually changed */
          {
            "bindings": {
              "enter": "newline"
            },
            "context": "Editor",
          },
        ]
      '';

      expectedContent = builtins.toFile "expected.json" ''
        [
          {
            "bindings": {
              "down": "menu::SelectNext",
              "up": "menu::SelectPrev"
            }
          },
          {
            "bindings": {
              "down": "select"
            },
            "context": "Terminal"
          },
          {
            "bindings": {
              "enter": "newline",
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
