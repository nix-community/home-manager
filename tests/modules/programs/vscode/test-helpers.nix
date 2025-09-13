{
  lib,
  pkgs,
  packageName,
  ...
}:
rec {
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  hasValue = attrs: key: (attrs ? "${key}") && (attrs.${key} != null);

  # default fork configuration
  #
  forkConfig =
    {
      vscode = {
        appName = "Code";
        extensionsDirectory = ".vscode/extensions";
        # configDirectory = null # defaults to mkTestAppUserDir
      };
      code-cursor = {
        appName = "Cursor";
        extensionsDirectory = ".cursor/extensions";
        # configDirectory = null # defaults to mkTestAppUserDir
      };
    }
    .${packageName};

  # Default per-fork path overrides used by tests.
  #
  # App User directory: default to the user configuration
  #
  # linux: ~/.config/Cursor/User
  # macos: ~/Library/Application Support/Cursor/User
  #
  mkTestAppUserDir =
    if isDarwin then
      builtins.trace "[userDirectory] macOS path: Library/Application Support/${forkConfig.appName}/User" "Library/Application Support/${forkConfig.appName}/User"
    else
      builtins.trace "[userDirectory] Linux path: ${forkConfig.appName}/User" "${forkConfig.appName}/User";

  # App Config directory: default to the app configuration (also where extensions are stored)
  #
  # config directory or user directory
  #
  mkTestAppConfigDir =
    if hasValue forkConfig "configDirectory" then
      builtins.trace "[configDirectory] custom config directory: ${forkConfig.configDirectory}" forkConfig.configDirectory
    else
      builtins.trace "[configDirectory] user directory: ${mkTestAppUserDir}" mkTestAppUserDir;

  # Compute the root directory for extensions for a given program
  mkTestAppExtensionsDir =
    if hasValue forkConfig "extensionsDirectory" then
      builtins.trace "[extensionsDirectory] custom extensions directory: ${forkConfig.extensionsDirectory}" forkConfig.extensionsDirectory
    else
      builtins.trace "[extensionsDirectory] user directory: ${mkTestAppConfigDir}/extensions" "${mkTestAppConfigDir}/extensions";

  # Generate stable JSON text for expected content
  toJSONText = value: lib.generators.toJSON { } value;

  # Write expected JSON content to a file for assertions
  writeExpected = name: value: pkgs.writeText name (toJSONText value);

  ##
  ## mocks
  ##

  # keybindings configuration (json object)
  #
  keybindingsJsonObject = [
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

  # keybindings configuration (json path)
  #
  keybindingsJsonPath = builtins.toFile "${packageName}-keybindings.json.test" ''
    [
      {
        "args": null,
        "command": "editor.action.clipboardCopyAction",
        "key": "ctrl+c",
        "when": "textInputFocus && false"
      },
      {
        "args": {
          "command": "echo file"
        },
        "command": "run",
        "key": "ctrl+r",
        "when": null
      }
    ]
  '';

  # mcp configuration (json object)
  #
  mcpJsonObject = {
    servers = {
      echo = {
        command = "echo";
      };
    };
  };

  # mcp configuration (json path)
  #
  mcpJsonPath = builtins.toFile "${packageName}-mcp.json.test" ''
    {
      "servers": {
        "echo": {
          "command": "echo"
        }
      }
    }
  '';

  # settings configuration (json object)
  #
  settingsJsonObject = {
    "files.autoSave" = "on";
  };

  # settings configuration (json path)
  #
  settingsJsonPath = builtins.toFile "${packageName}-settings.json.test" ''
    {
      "files.autoSave": "on"
    }
  '';

  # tasks configuration (json object)
  #
  tasksJsonObject = {
    version = "2.0.0";
    tasks = [
      {
        type = "shell";
        label = "Hello task";
        command = "hello";
      }
    ];
  };

  # tasks configuration (json path)
  #
  tasksJsonPath = builtins.toFile "${packageName}-tasks.json.test" ''
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
}
