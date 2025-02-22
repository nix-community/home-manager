{ pkgs, lib, ... }:

let

  tasksFilePath = name:
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }tasks.json"
    else
      ".config/Code/User/${
        lib.optionalString (name != "default") "profiles/${name}/"
      }tasks.json";

  tasks = {
    version = "2.0.0";
    tasks = [{
      type = "shell";
      label = "Hello task";
      command = "hello";
    }];
  };

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

in {
  programs.vscode = {
    enable = true;
    package = pkgs.writeScriptBin "vscode" "" // {
      pname = "vscode";
      version = "1.75.0";
    };
    profiles = {
      default.userTasks = tasks;
      test.userTasks = tasks;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/${tasksFilePath "default"}"
    assertFileContent "home-files/${tasksFilePath "default"}" "${expectedTasks}"

    assertFileExists "home-files/${tasksFilePath "test"}"
    assertFileContent "home-files/${tasksFilePath "test"}" "${expectedTasks}"
  '';
}
