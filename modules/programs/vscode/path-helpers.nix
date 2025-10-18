{
  cfg,
  lib,
  pkgs,
}:
rec {
  ## VS Code directories and config paths
  #
  # DISCLAIMER: most of the apps use the same paths to store their data adapted
  # to the app name and other options, however there are some specific
  # exceptions, which we must support by using the `overridePaths` option in
  # the `mkVSCodeFork` function.
  #
  ## Supported VS Code forks:
  #
  # | package          | pname    | executableName  | longName            |
  # |------------------|----------|-----------------|---------------------|
  # | pkgs.vscode      | vscode   | code            | Visual Studio Code  |
  # | pkgs.code-cursor | cursor   | cursor          | Cursor              |
  # | pkgs.windsurf    | windsurf | windsurf        | Windsurf            |
  #
  ## Home config directory: per app
  #
  #  Home config directory is inferred by the `package.pname`.
  #
  #  - cursor: ~/.cursor
  #  - vscode: ~/.vscode
  #  - windsurf: ~/.windsurf
  #
  ## User directory: per system
  #
  #  User directory depends on the system it's running on.
  #  The application folder name is inferred by the `package.executableName`.
  #
  #  - darwin
  #    - cursor: ~/Library/Application Support/Cursor/User
  #    - vscode: ~/Library/Application Support/Code/User
  #    - windsurf: ~/Library/Application Support/Windsurf/User
  #  - linux
  #    - cursor: ~/.config/Cursor/User
  #    - vscode: ~/.config/Code/User
  #    - windsurf: ~/.config/Windsurf/User
  #
  ## Extensions directory: per app (home config directory + /extensions)
  #
  #  Extensions are installed in the home config directory.
  #  It can be overridden using the `overridePaths.extensions` option.
  #
  #  - cursor: ~/.cursor/extensions
  #  - vscode: ~/.vscode/extensions
  #  - windsurf: ~/.windsurf/extensions
  #
  ## Profile directory: per profile (user directory + /profiles/ + profile name)
  #
  #  Profiles are stored in the user directory and depends on the profile name.
  #
  #  Default profile is stored in the user directory and other profiles are
  #  stored in the user directory under the `profiles` directory.
  #
  #  - default: ~/Library/Application Support/Code/User
  #  - library: ~/Library/Application Support/Code/User/profiles/library
  #
  ## Snippets directory: per profile (user directory + /profiles/ + profile name + /snippets)
  #
  #  - default: ~/Library/Application Support/Code/User/snippets
  #  - library: ~/Library/Application Support/Code/User/profiles/library/snippets
  #
  ## Config files: per profile
  #
  #  - settings: per profile (user directory + /profiles/ + profile name + /settings.json)
  #    - default: ~/Library/Application Support/Code/User/settings.json
  #    - library: ~/Library/Application Support/Code/User/profiles/library/settings.json
  #
  #  - keybindings: per profile (user directory + /profiles/ + profile name + /keybindings.json)
  #    - default: ~/Library/Application Support/Code/User/keybindings.json
  #    - library: ~/Library/Application Support/Code/User/profiles/library/keybindings.json
  #
  #  - tasks: per profile (user directory + /profiles/ + profile name + /tasks.json)
  #    - default: ~/Library/Application Support/Code/User/tasks.json
  #    - library: ~/Library/Application Support/Code/User/profiles/library/tasks.json
  #
  #  - mcp: per profile (user directory + /profiles/ + profile name + /mcp.json)
  #    - default: ~/Library/Application Support/Code/User/mcp.json
  #    - library: ~/Library/Application Support/Code/User/profiles/library/mcp.json
  #
  #  - snippets
  #    - global: per profile (user directory + /profiles/ + profile name + /snippets/global.json)
  #      - default: ~/Library/Application Support/Code/User/snippets/global.json
  #      - library: ~/Library/Application Support/Code/User/profiles/library/snippets/global.json
  #    - language: per profile (user directory + /profiles/ + profile name + /snippets/language.json)
  #      - default: ~/Library/Application Support/Code/User/snippets/haskell.json
  #      - library: ~/Library/Application Support/Code/User/profiles/library/snippets/haskell.json
  #
  inherit (builtins) substring stringLength;
  inherit (lib.strings) toLower toUpper;

  jsonFormat = pkgs.formats.json { };
  toPretty = lib.generators.toPretty { };

  capitalize =
    string: toUpper (substring 0 1 string) + toLower (substring 1 ((stringLength string) - 1) string);

  jsonSource =
    name: value:
    if builtins.isPath value || lib.isStorePath value then
      value
    else
      jsonFormat.generate "${cfg.package.pname}-${name}-json" value;

  hasValue = value: value != null && value != "" && value != [ ] && value != { };
  hasAttrKey = key: attrs: (builtins.hasAttr key attrs) && (hasValue attrs.${key});
  getAttrKey = key: attrs: if (hasAttrKey key attrs) then attrs.${key} else null;

  joinPaths = paths: lib.concatStringsSep "/" (lib.filter hasValue paths);

  ## Home config directory: per app
  #
  #  Home config directory is inferred by the `package.pname` (lowercase).
  #
  #  - cursor: ~/.cursor
  #  - vscode: ~/.vscode
  #  - windsurf: ~/.windsurf
  #
  homeConfigDirectory = ".${toLower cfg.package.pname}";

  ## Application user directory
  #
  #  Application user directory depends on the system it's running on and the application name.
  #  The application name is inferred by the `package.executableName` (capitalized).
  #
  #  - darwin
  #    - cursor: ~/Library/Application Support/Cursor/User
  #    - vscode: ~/Library/Application Support/Code/User
  #    - windsurf: ~/Library/Application Support/Windsurf/User
  #  - linux
  #    - cursor: ~/.config/Cursor/User
  #    - vscode: ~/.config/Code/User
  #    - windsurf: ~/.config/Windsurf/User
  #
  appName = capitalize cfg.package.executableName;

  userDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${appName}/User"
    else
      ".config/${appName}/User";

  ## Extensions directory
  #
  #  Extensions are installed in the home config directory.
  #  It can be overridden using the `overridePaths.extensions` option.
  #
  #  - cursor: ~/.cursor/extensions
  #  - vscode: ~/.vscode/extensions
  #  - windsurf: ~/.windsurf/extensions
  #
  extensionsDirectory = "${homeConfigDirectory}/extensions";

  ## Profile directory
  #
  #  Profiles are stored in the user directory and depends on the profile name.
  #
  #  Default profile is stored in the user directory and other profiles are
  #  stored in the user directory under the `profiles` directory.
  #
  #  - default: ~/Library/Application Support/Code/User
  #  - library: ~/Library/Application Support/Code/User/profiles/library
  #
  profileFolder = profileName: if profileName == "default" then "" else "profiles/${profileName}";

  profileDirectory =
    profileName:
    joinPaths [
      userDirectory
      (profileFolder profileName)
    ];

  ## Snippets directory
  #
  #  Snippets are stored in the profile directory.
  #
  #  Global snippets are saved as `global.json` and language snippets are saved as `${language}.json`.
  #
  #  - default: ~/Library/Application Support/Code/User/snippets
  #  - library: ~/Library/Application Support/Code/User/profiles/library/snippets
  #
  snippetsDirectory =
    profileName:
    joinPaths [
      (profileDirectory profileName)
      "snippets"
    ];

  settingsDirectory =
    profileName: configKey:
    if isCursorMcp configKey && isDefaultProfile profileName then
      joinPaths [
        cfg.homeDirectory
        homeConfigDirectory
      ]
    else
      (profileDirectory profileName);

  isCursorMcp = configKey: cfg.packageName == "code-cursor" && configKey == "mcp";
  isDefaultProfile = profileName: profileName == "default";

  mkConfigFilePair =
    profileName: storeDir: configKey: configValue:
    let
      sourceFilename = configKey;
      sourceFilePath = "${storeDir}/${sourceFilename}.json";

      storeFilename = "${lib.optionalString cfg.mutableProfile ".immutable-"}${sourceFilename}";
      storeFilePath = "${storeDir}/${storeFilename}.json";

      configFile = {
        source = jsonSource "${profileName}-user-${configKey}" configValue;

        onChange = lib.mkIf cfg.mutableProfile ''
          echo "Regenerating file from source: ${storeFilename}.json -> ${sourceFilename}.json"
          run cp -vf "$HOME/${storeFilePath}" "$HOME/${sourceFilePath}"
        '';
      };
    in
    lib.nameValuePair storeFilePath configFile;

}
