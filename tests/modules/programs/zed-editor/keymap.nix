{ config, lib, ... }:

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

  home.homeDirectory = lib.mkForce "/build/hm-user";

  nmt.script =
    let
      preexistingKeymaps = builtins.toFile "preexisting.json" ''
        [
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
          {
            "bindings": {
              "enter": "newline"
            },
            "context": "Editor"
          }
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
              "enter": "newline",
              "escape": "editor::Cancel"
            },
            "context": "Editor"
          },
          {
            "bindings": {
              "down": "select"
            },
            "context": "Terminal"
          }
        ]
      '';

      keymapPath = ".config/zed/keymap.json";
    in
    ''
      export HOME=${config.home.homeDirectory}

      # Simulate preexisting keymaps
      mkdir -p $HOME/.config/zed
      cat ${preexistingKeymaps} > $HOME/${keymapPath}

      # Run the activation script
      ${config.home.activation.zedKeymapActivation.data}

      # Validate the merged keymaps
      assertFileExists "$HOME/${keymapPath}"
      assertFileContent "$HOME/${keymapPath}" "${expectedContent}"

      # Test idempotency
      ${config.home.activation.zedKeymapActivation.data}
      assertFileExists "$HOME/${keymapPath}"
      assertFileContent "$HOME/${keymapPath}" "${expectedContent}"
    '';
}
