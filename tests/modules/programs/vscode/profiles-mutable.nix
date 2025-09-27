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
          keybindings = helpers.keybindingsJsonPath;
          mcp = helpers.mcpJsonObject;
          settings = helpers.settingsJsonPath;
          tasks = helpers.tasksJsonObject;
        };
      };
    })
    // {
      nmt.script = ''
        # immutable-mcp.json (dynamic path based on the package name)
        #
        assertFileExists "home-files/${mcpPath}/.mcp-immutable.json"
        assertFileContent "home-files/${mcpPath}/.mcp-immutable.json" "${helpers.mcpJsonPath}"

        # immutable-keybindings.json
        #
        assertFileExists "home-files/${configPath}/.keybindings-immutable.json"
        assertFileContent "home-files/${configPath}/.keybindings-immutable.json" "${helpers.keybindingsJsonPath}"

        # immutable-settings.json
        #
        assertFileExists "home-files/${configPath}/.settings-immutable.json"
        assertFileContent "home-files/${configPath}/.settings-immutable.json" "${helpers.settingsJsonPath}"

        # immutable-tasks.json
        #
        assertFileExists "home-files/${configPath}/.tasks-immutable.json"
        assertFileContent "home-files/${configPath}/.tasks-immutable.json" "${helpers.tasksJsonPath}"
      '';
    };
}
