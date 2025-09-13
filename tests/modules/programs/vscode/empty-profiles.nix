{ modulePath, packageName, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  helpers = import ./test-helpers.nix { inherit lib pkgs packageName; };
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
    })
    // {
      nmt.script = ''
        # no profile files are created
        #
        assertPathNotExists "home-files/${helpers.mkTestAppUserDir}/.immutable-keybindings.json"
        assertPathNotExists "home-files/${helpers.mkTestAppUserDir}/keybindings.json"

        assertPathNotExists "home-files/${helpers.mkTestAppUserDir}/.immutable-settings.json"
        assertPathNotExists "home-files/${helpers.mkTestAppUserDir}/settings.json"

        assertPathNotExists "home-files/${helpers.mkTestAppUserDir}/.immutable-tasks.json"
        assertPathNotExists "home-files/${helpers.mkTestAppUserDir}/tasks.json"

        # mcp is stored in the config directory
        #
        assertPathNotExists "home-files/${helpers.mkTestAppConfigDir}/.immutable-mcp.json"
        assertPathNotExists "home-files/${helpers.mkTestAppConfigDir}/mcp.json"
      '';
    };
}
