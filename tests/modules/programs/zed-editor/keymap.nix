{
  config,
  lib,
  pkgs,
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
      activationScript = pkgs.writeScript "activation" config.home.activation.zedKeymapActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting keymaps
      mkdir -p $HOME/.config/zed
      cat ${preexistingKeymaps} > $HOME/${keymapPath}

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the merged keymaps
      assertFileExists "$HOME/${keymapPath}"
      assertFileContent "$HOME/${keymapPath}" "${expectedContent}"

      # Test idempotency
      $TMPDIR/activate
      assertFileExists "$HOME/${keymapPath}"
      assertFileContent "$HOME/${keymapPath}" "${expectedContent}"
    '';
}
