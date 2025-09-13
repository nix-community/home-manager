{
  lib,
  pkgs,
  packageName,
  ...
}:
rec {
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  hasValue = attrs: key: (attrs ? "${key}") && (attrs.${key} != null);

  # default per-fork path overrides
  #
  defaultOverridePaths = {
    code-cursor = {
      mcp = ".cursor";
    };
  };

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
  # if the config directory is set, use it
  # otherwise, use the user directory
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
}
