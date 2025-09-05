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
      # are read-only because of the nix store.
      #
      profiles = {
        default = profile;
        work = profile;
        test = profile;
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
          # keybindings.json
          #
          assertFileExists "home-files/${profileConfig "default" "keybindings"}/keybindings.json"
          assertFileContent "home-files/${profileConfig "default" "keybindings"}/keybindings.json" "${keybindingsJson}"

          # mcp.json
          #
          assertFileExists "home-files/${profileConfig "default" "mcp"}/mcp.json"
          assertFileContent "home-files/${profileConfig "default" "mcp"}/mcp.json" "${mcpJson}"

          # settings.json
          #
          assertFileExists "home-files/${profileConfig "default" "settings"}/settings.json"
          assertFileContent "home-files/${profileConfig "default" "settings"}/settings.json" "${settingsJson}"

          # tasks.json
          #
          assertFileExists "home-files/${profileConfig "default" "tasks"}/tasks.json"
          assertFileContent "home-files/${profileConfig "default" "tasks"}/tasks.json" "${tasksJson}"

          # the immutable markers don't need to be created
          #
          assertPathNotExists "home-files/${profileConfig "default" "keybindings"}/.immutable-keybindings.json"
          assertPathNotExists "home-files/${profileConfig "default" "mcp"}/.immutable-mcp.json"
          assertPathNotExists "home-files/${profileConfig "default" "settings"}/.immutable-settings.json"
          assertPathNotExists "home-files/${profileConfig "default" "tasks"}/.immutable-tasks.json"
        '';
    };
}
