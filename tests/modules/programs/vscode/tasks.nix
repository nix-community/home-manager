{ pkgs, ... }:

let

  tasksFilePath = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/Code/User/tasks.json"
  else
    ".config/Code/User/tasks.json";

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
    package = pkgs.writeScriptBin "vscode" "" // { pname = "vscode"; };
    userTasks = tasks;
  };

  nmt.script = ''
    assertFileExists "home-files/${tasksFilePath}"
    assertFileContent "home-files/${tasksFilePath}" "${expectedTasks}"
  '';
}
