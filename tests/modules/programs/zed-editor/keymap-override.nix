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
        context = "Editor";
        bindings = {
          escape = "editor::Cancel";
        };
      }
    ];
    preserveUserKeymaps = false;
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingKeymaps = builtins.toFile "preexisting.json" ''
        [
          {
            "context": "Workspace",
            "bindings": {
              "ctrl-shift-t": "workspace::NewTerminal"
            }
          }
        ]
      '';

      expectedContent = builtins.toFile "expected.json" ''
        [
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

      echo not-readonly >> $HOME/${keymapPath}
    '';
}
