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
    userTasks = [
      {
        label = "Format Code";
        command = "nix";
        args = [
          "fmt"
          "$ZED_WORKTREE_ROOT"
        ];
        allow_concurrent_runs = false;
      }
    ];
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingTasks = builtins.toFile "preexisting.json" "";

      expectedContent = builtins.toFile "expected.json" ''
        [
          {
            "allow_concurrent_runs": false,
            "args": [
              "fmt",
              "$ZED_WORKTREE_ROOT"
            ],
            "command": "nix",
            "label": "Format Code"
          }
        ]
      '';

      taskPath = ".config/zed/tasks.json";
      activationScript = pkgs.writeScript "activation" config.home.activation.zedTasksActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting tasks
      mkdir -p $HOME/.config/zed
      cat ${preexistingTasks} > $HOME/${taskPath}

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the merged tasks
      assertFileExists "$HOME/${taskPath}"
      assertFileContent "$HOME/${taskPath}" "${expectedContent}"

      # Test idempotency
      $TMPDIR/activate
      assertFileExists "$HOME/${taskPath}"
      assertFileContent "$HOME/${taskPath}" "${expectedContent}"
    '';
}
