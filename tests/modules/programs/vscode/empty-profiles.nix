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
          # no profile files are created
          #
          assertPathNotExists "home-files/${profileConfig "default" "keybindings"}/.immutable-keybindings.json"
          assertPathNotExists "home-files/${profileConfig "default" "keybindings"}/keybindings.json"
          assertPathNotExists "home-files/${profileConfig "default" "mcp"}/.immutable-mcp.json"
          assertPathNotExists "home-files/${profileConfig "default" "mcp"}/mcp.json"
          assertPathNotExists "home-files/${profileConfig "default" "settings"}/.immutable-settings.json"
          assertPathNotExists "home-files/${profileConfig "default" "settings"}/settings.json"
          assertPathNotExists "home-files/${profileConfig "default" "tasks"}/.immutable-tasks.json"
          assertPathNotExists "home-files/${profileConfig "default" "tasks"}/tasks.json"
        '';
    };
}
