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
        assertFileExists "home-files/${mcpPath}/.immutable-mcp.json"
        assertFileContent "home-files/${mcpPath}/.immutable-mcp.json" "${helpers.mcpJsonPath}"

        # immutable-keybindings.json
        #
        assertFileExists "home-files/${configPath}/.immutable-keybindings.json"
        assertFileContent "home-files/${configPath}/.immutable-keybindings.json" "${helpers.keybindingsJsonPath}"

        # immutable-settings.json
        #
        assertFileExists "home-files/${configPath}/.immutable-settings.json"
        assertFileContent "home-files/${configPath}/.immutable-settings.json" "${helpers.settingsJsonPath}"

        # immutable-tasks.json
        #
        assertFileExists "home-files/${configPath}/.immutable-tasks.json"
        assertFileContent "home-files/${configPath}/.immutable-tasks.json" "${helpers.tasksJsonPath}"
      '';
    };
}
