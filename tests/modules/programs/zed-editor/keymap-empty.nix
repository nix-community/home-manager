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
