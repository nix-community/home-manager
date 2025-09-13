{ modulePath, packageName, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  helpers = import ./test-helpers.nix { inherit lib pkgs packageName; };

  configPath =
    {
      vscode = helpers.mkTestAppUserDir; # user settings path
      code-cursor = helpers.mkTestAppConfigDir; # fallback to user settings path
    }
    .${packageName};

  mcpPath =
    {
      vscode = configPath; # user settings path
      code-cursor = ".cursor"; # override mcp path to: .cursor
    }
    .${packageName};

  keybindings = [
    {
      key = "ctrl+c";
      command = "editor.action.clipboardCopyAction";
      when = "textInputFocus && false";
    }
    {
      key = "ctrl+r";
      command = "run";
      args = {
        command = "echo file";
      };
    }
  ];

  keybindingsJson = builtins.toFile "${packageName}-immutable-keybindings.json.expected" ''
    [
      {
        "key": "ctrl+c",
        "command": "editor.action.clipboardCopyAction",
        "when": "textInputFocus && false"
      },
      {
        "key": "ctrl+r",
        "command": "run",
        "args": {
          "command": "echo file"
        }
      }
    ]
  '';

  mcp = {
    servers = {
      echo = {
        command = "echo";
      };
    };
  };

  mcpJson = builtins.toFile "${packageName}-immutable-mcp.json.expected" ''
    {
      "servers": {
        "echo": {
          "command": "echo"
        }
      }
    }
  '';

  settings = {
    "files.autoSave" = "on";
  };

  settingsJson = builtins.toFile "${packageName}-immutable-settings.json.expected" ''
    {
      "files.autoSave": "on"
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

  tasksJson = builtins.toFile "${packageName}-immutable-tasks.json.expected" ''
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
in
{
  config =
    { }
    // lib.setAttrByPath modulePath ({
      enable = true;

      package = config.lib.test.mkStubPackage {
        name = packageName;
        version = "1.75.0";
      };

      # when only default profile is defined, default profile is mutable by default
      # this ensures that the profile can be modified by the user and the files are
      # regenerated when the profile is changed.
      #
      profiles = {
        default = {
          keybindings = keybindingsJson; # file path
          mcp = mcp; # json object
          settings = settings; # json object
          tasks = tasks; # json object
        };
      };
    })
    // {
      nmt.script = ''
        # immutable-mcp.json (dynamic path based on the package name)
        #
        assertFileExists "home-files/${mcpPath}/.immutable-mcp.json"
        assertFileContent "home-files/${mcpPath}/.immutable-mcp.json" "${mcpJson}"

        # immutable-keybindings.json
        #
        assertFileExists "home-files/${configPath}/.immutable-keybindings.json"
        assertFileContent "home-files/${configPath}/.immutable-keybindings.json" "${keybindingsJson}"

        # immutable-settings.json
        #
        assertFileExists "home-files/${configPath}/.immutable-settings.json"
        assertFileContent "home-files/${configPath}/.immutable-settings.json" "${settingsJson}"

        # immutable-tasks.json
        #
        assertFileExists "home-files/${configPath}/.immutable-tasks.json"
        assertFileContent "home-files/${configPath}/.immutable-tasks.json" "${tasksJson}"
      '';
    };
}
