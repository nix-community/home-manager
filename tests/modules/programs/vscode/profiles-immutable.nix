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

  # cursor stores mcp.json in the config directory
  #
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

      # when multiple profiles are defined, the profiles are immutable by default.
      # this ensures that the profiles are not modified by mistake, so the files
      # are read-only enforced by the nix store.
      #
      profiles = {
        default = {
          keybindings = helpers.keybindingsJsonPath;
          mcp = helpers.mcpJsonObject;
          settings = helpers.settingsJsonPath;
          tasks = helpers.tasksJsonObject;
        };

        work = {
          keybindings = helpers.keybindingsJsonObject;
          mcp = helpers.mcpJsonPath;
          settings = helpers.settingsJsonObject;
          tasks = helpers.tasksJsonPath;
        };
      };
    })
    // {
      nmt.script = ''
        # mcp.json (dynamic path based on the package name)
        #
        assertFileExists "home-files/${mcpPath}/mcp.json"
        assertFileContent "home-files/${mcpPath}/mcp.json" "${helpers.mcpJsonPath}"
        assertPathNotExists "home-files/${mcpPath}/.mcp-immutable.json"

        # keybindings.json
        #
        assertFileExists "home-files/${configPath}/keybindings.json"
        assertFileContent "home-files/${configPath}/keybindings.json" "${helpers.keybindingsJsonPath}"
        assertPathNotExists "home-files/${configPath}/.keybindings-immutable.json"

        # settings.json
        #
        assertFileExists "home-files/${configPath}/settings.json"
        assertFileContent "home-files/${configPath}/settings.json" "${helpers.settingsJsonPath}"
        assertPathNotExists "home-files/${configPath}/.settings-immutable.json"

        # tasks.json
        #
        assertFileExists "home-files/${configPath}/tasks.json"
        assertFileContent "home-files/${configPath}/tasks.json" "${helpers.tasksJsonPath}"
        assertPathNotExists "home-files/${configPath}/.tasks-immutable.json"
      '';
    };
}
