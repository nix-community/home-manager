{
  lib,
  package,
  packageName ? package.pname,
  pkgs,
  ...
}:
rec {
  inherit (builtins) substring stringLength;
  inherit (lib.strings) toLower toUpper;

  capitalize =
    string: toUpper (substring 0 1 string) + toLower (substring 1 ((stringLength string) - 1) string);

  appName = capitalize package.executableName;

  userDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${appName}/User"
    else
      ".config/${appName}/User";

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

  # snippets configuration (json object)
  #
  globalSnippetsObject = {
    todo = {
      prefix = [ "todo" ];
      body = [ "# TODO: $0" ];
      description = "Insert a TODO comment";
    };
  };

  globalSnippetsJsonPath = builtins.toFile "${packageName}-user-global-snippets.json.test" ''
    {
      "todo": {
        "body": [
          "# TODO: $0"
        ],
        "description": "Insert a TODO comment",
        "prefix": [
          "todo"
        ]
      }
    }
  '';

  elixirSnippetsObject = {
    pry = {
      prefix = [ "pry" ];
      body = [ "require IEx; IEx.pry" ];
      description = "Insert a debug Pry statement for a function";
    };

    pipepry = {
      prefix = [ "ppry" ];
      body = [ "|> tap(fn input -> IO.inspect(input); require IEx; IEx.pry(); end)" ];
      description = "Insert a debug Pry statement for a pipe";
    };
  };

  elixirSnippetsJsonPath = builtins.toFile "${packageName}-user-elixir-snippets.json.test" ''
    {
      "pipepry": {
        "body": [
          "|> tap(fn input -> IO.inspect(input); require IEx; IEx.pry(); end)"
        ],
        "description": "Insert a debug Pry statement for a pipe",
        "prefix": [
          "ppry"
        ]
      },
      "pry": {
        "body": [
          "require IEx; IEx.pry"
        ],
        "description": "Insert a debug Pry statement for a function",
        "prefix": [
          "pry"
        ]
      }
    }
  '';

  haskellSnippetsObject = {
    impl = {
      prefix = [ "impl" ];
      body = [ "impl body in user haskell snippet" ];
      description = "Insert an implementation stub";
    };
  };

  haskellSnippetsJsonPath = builtins.toFile "${packageName}-user-haskell-snippets.json.test" ''
    {
      "impl": {
        "body": [
          "impl body in user haskell snippet"
        ],
        "description": "Insert an implementation stub",
        "prefix": [
          "impl"
        ]
      }
    }
  '';
}
