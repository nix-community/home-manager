package:

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.vscode;
  willUseIfd = package.pname != "vscode";

  tasksFilePath =
    name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${cfg.nameShort}/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }tasks.json"
    else
      ".config/${cfg.nameShort}/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }tasks.json";

  content = ''
    {
      // Comments should be preserved
      "tasks": [
        {
          "command": "hello",
          "label": "Hello task",
          "type": "shell"
        },
        {
          "command": "world",
          "label": "World task",
          "type": "shell"
        }
      ],
      "version": "2.0.0"
    }
  '';

  tasks = {
    version = "2.0.0";
    tasks = [
      {
        type = "shell";
        label = "Hello task";
        command = "hello";
      }
    ];
  };

  customTasksPath = pkgs.writeText "custom.json" content;

  expectedTasks = pkgs.writeText "tasks-expected.json" ''
    {
      "tasks": [
        {
          "command": "hello",
          "label": "Hello task",
          "type": "shell"
        }
      ],
      "version": "2.0.0"
    }
  '';

  expectedCustomTasks = pkgs.writeText "custom-expected.json" content;
in

lib.mkIf (willUseIfd -> config.test.enableLegacyIfd) {
  programs.vscode = {
    enable = true;
    inherit package;
    profiles = {
      default.userTasks = tasks;
      test.userTasks = tasks;
      custom.userTasks = customTasksPath;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${tasksFilePath "default"}"
    assertFileContent "home-files/${tasksFilePath "default"}" "${expectedTasks}"

    assertFileExists "home-files/${tasksFilePath "test"}"
    assertFileContent "home-files/${tasksFilePath "test"}" "${expectedTasks}"

    assertFileExists "home-files/${tasksFilePath "custom"}"
    assertFileContent "home-files/${tasksFilePath "custom"}" "${expectedCustomTasks}"
  '';
}
