{
  config,
  lib,
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
    in
    config.lib.test.runMutableConfigTest {
      files.${taskPath} = preexistingTasks;
      expected.${taskPath} = expectedContent;
    };
}
