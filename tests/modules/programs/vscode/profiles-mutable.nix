{
  modulePath,
  packageName,
  configDirName,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  overridePaths = {
    code-cursor = {
      mcp = ".cursor";
    };
  };

  hasOverridePath = pname: key: overridePaths ? "${pname}" && overridePaths.${pname} ? "${key}";

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
      nmt.script =
        let
          cfg = lib.getAttrFromPath modulePath config;

          profileConfig =
            profileName: key:
            lib.concatStringsSep "/" [
              (
                if hasOverridePath cfg.package.pname key then
                  overridePaths.${cfg.package.pname}.${key}
                else if pkgs.stdenv.hostPlatform.isDarwin then
                  "Library/Application Support/${configDirName}/User"
                else
                  ".config/${configDirName}/User"
              )
              (lib.optionalString (profileName != "default") "profiles/${profileName}")
            ];
        in
        ''
          # immutable-keybindings.json
          #
          assertFileExists "home-files/${profileConfig "default" "keybindings"}/.immutable-keybindings.json"
          assertFileContent "home-files/${profileConfig "default" "keybindings"}/.immutable-keybindings.json" "${keybindingsJson}"

          # immutable-mcp.json
          #
          assertFileExists "home-files/${profileConfig "default" "mcp"}/.immutable-mcp.json"
          assertFileContent "home-files/${profileConfig "default" "mcp"}/.immutable-mcp.json" "${mcpJson}"

          # immutable-settings.json
          #
          assertFileExists "home-files/${profileConfig "default" "settings"}/.immutable-settings.json"
          assertFileContent "home-files/${profileConfig "default" "settings"}/.immutable-settings.json" "${settingsJson}"

          # immutable-tasks.json
          #
          assertFileExists "home-files/${profileConfig "default" "tasks"}/.immutable-tasks.json"
          assertFileContent "home-files/${profileConfig "default" "tasks"}/.immutable-tasks.json" "${tasksJson}"

          # the mutable versions are copied only during activation
          #
          assertPathNotExists "home-files/${profileConfig "default" "keybindings"}keybindings.json"
          assertPathNotExists "home-files/${profileConfig "default" "settings"}settings.json"
          assertPathNotExists "home-files/${profileConfig "default" "mcp"}mcp.json"
          assertPathNotExists "home-files/${profileConfig "default" "tasks"}tasks.json"
        '';
    };
}
