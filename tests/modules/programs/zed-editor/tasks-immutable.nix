# Test custom keymap functionality
{ config, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    mutableUserTasks = false;
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

  nmt.script =
    let
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

      settingsPath = ".config/zed/tasks.json";
    in
    ''
      assertFileExists "home-files/${settingsPath}"
      assertFileContent "home-files/${settingsPath}" "${expectedContent}"
    '';
}
