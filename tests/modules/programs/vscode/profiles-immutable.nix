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

  keybindingsJson = builtins.toFile "${packageName}-keybindings.expected" ''
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

  mcpJson = builtins.toFile "${packageName}-mcp.expected" ''
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

  settingsJson = builtins.toFile "${packageName}-settings.expected" ''
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

  tasksJson = builtins.toFile "${packageName}-tasks.expected" ''
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

  profile = {
    keybindings = keybindingsJson; # file path
    mcp = mcp; # json object
    settings = settings; # json object
    tasks = tasks; # json object
  };
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

      # when multiple profiles are defined, the profiles are immutable by default.
      # this ensures that the profiles are not modified by mistake, so the files
      # are read-only enforced by the nix store.
      #
      profiles = {
        default = profile;
        work = profile;
        test = profile;
      };
    })
    // {
      nmt.script = ''
        # mcp.json (dynamic path based on the package name)
        #
        assertFileExists "home-files/${mcpPath}/mcp.json"
        assertFileContent "home-files/${mcpPath}/mcp.json" "${mcpJson}"
        assertPathNotExists "home-files/${mcpPath}/.immutable-mcp.json"

        # keybindings.json
        #
        assertFileExists "home-files/${configPath}/keybindings.json"
        assertFileContent "home-files/${configPath}/keybindings.json" "${keybindingsJson}"
        assertPathNotExists "home-files/${configPath}/.immutable-keybindings.json"

        # settings.json
        #
        assertFileExists "home-files/${configPath}/settings.json"
        assertFileContent "home-files/${configPath}/settings.json" "${settingsJson}"
        assertPathNotExists "home-files/${configPath}/.immutable-settings.json"

        # tasks.json
        #
        assertFileExists "home-files/${configPath}/tasks.json"
        assertFileContent "home-files/${configPath}/tasks.json" "${tasksJson}"
        assertPathNotExists "home-files/${configPath}/.immutable-tasks.json"
      '';
    };
}
