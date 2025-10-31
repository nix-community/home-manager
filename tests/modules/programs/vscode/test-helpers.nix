{
  forkInputs,
  lib,
  pkgs,
  ...
}:
rec {
  # inherit (builtins) trace toJSON;

  # toPretty = lib.generators.toPretty { };

  vscodePackageVersion =
    if forkInputs.package ? vscodeVersion then
      forkInputs.package.vscodeVersion
    else
      forkInputs.package.version;

  supportsMultiProfiles = lib.versionAtLeast vscodePackageVersion "1.74.0";

  isMutableProfile = ((forkInputs ? mutableProfile) && forkInputs.mutableProfile);

  userDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${forkInputs.package.longName}/User"
    else
      ".config/${forkInputs.package.longName}/User";

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
  keybindingsJsonPath = builtins.toFile "${forkInputs.package.pname}-keybindings.json.test" ''
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
  mcpJsonPath = builtins.toFile "${forkInputs.package.pname}-mcp.json.test" ''
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
  settingsJsonPath = builtins.toFile "${forkInputs.package.pname}-settings.json.test" ''
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
  tasksJsonPath = builtins.toFile "${forkInputs.package.pname}-tasks.json.test" ''
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

  globalSnippetsJsonPath = builtins.toFile "${forkInputs.package.pname}-user-global-snippets.json.test" ''
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

  elixirSnippetsJsonPath = builtins.toFile "${forkInputs.package.pname}-user-elixir-snippets.json.test" ''
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

  haskellSnippetsJsonPath = builtins.toFile "${forkInputs.package.pname}-user-haskell-snippets.json.test" ''
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
