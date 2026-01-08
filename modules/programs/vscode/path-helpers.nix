{
  cfg,
  lib,
  pkgs,
}:
rec {
  ## VS Code directories and config paths
  #
  # DISCLAIMER: most of the apps use the same paths to store their data adapted
  # to the app name and other options.
  #
  ## Supported VS Code forks:
  #
  # | package                   | pname            | executableName  | longName                       | shortName         |
  # |---------------------------|------------------|-----------------|--------------------------------|-------------------|
  # | pkgs.vscode               | vscode           | code            | Visual Studio Code             | Code              |
  # | pkgs.vscode-insiders      | vscode-insiders  | code-insiders   | Visual Studio Code - Insiders  | Code - Insiders   |
  # | pkgs.code-cursor          | cursor           | cursor          | Cursor                         | cursor            |
  # | pkgs.windsurf             | windsurf         | windsurf        | Windsurf                       | windsurf          |
  # | pkgs.vscodium             | vscodium         | codium          | VSCodium                       | vscodium          |
  #
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  jsonFormat = pkgs.formats.json { };

  isStorePath = value: builtins.isPath value || lib.isStorePath value;

  jsonSource =
    name: value:
    if isStorePath value then value else jsonFormat.generate "${cfg.package.pname}-${name}-json" value;

  hasValue = value: value != null && value != "" && value != [ ] && value != { };
  hasAttrKey = key: attrs: (builtins.hasAttr key attrs) && (hasValue attrs.${key});
  getAttrKey = key: attrs: if (hasAttrKey key attrs) then attrs.${key} else null;

  joinPaths = paths: lib.concatStringsSep "/" (lib.filter hasValue paths);

  ## Application user directory
  #
  #  Application user directory depends on the system it's running on and the application name.
  #  The application name is inferred by the `package.longName`.
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
  appName = cfg.package.longName;

  appDirectory = if cfg.package.pname == "vscode" then "Code" else cfg.package.longName;

  userDirectory = joinPaths [
    cfg.homeDirectory
    (if isDarwin then "Library/Application Support" else ".config")
    "${appDirectory}/User"
  ];

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

  ## Config file helpers
  #
  #  - mkConfigFile: creates a config file in the store directory
  #    - storeKey: the key to store the config file
  #    - storeDirectory: the directory to store the config file
  #    - sourceFilename: the filename of the config file
  #    - content: the content of the config file
  #
  #   returns a name value pair with the following attributes:
  #    - name: the store file path (storeDirectory + storeFilename (immutable prefix if mutable profile) + fileExtension)
  #    - value: the config json file (source file content)
  #      - onChange: generate a mutable config copy from the source file if the profile is mutable
  #
  mkConfigFile =
    {
      storeKey,
      storeDirectory,
      sourceFilename,
      content,
    }:
    let
      fileExtension = (lib.optionalString (!lib.hasSuffix ".code-snippets" sourceFilename) ".json");
      storeFilename = "${lib.optionalString cfg.mutableProfile ".immutable-"}${sourceFilename}";

      sourceFilePath = "${storeDirectory}/${sourceFilename}${fileExtension}";
      storeFilePath = "${storeDirectory}/${storeFilename}${fileExtension}";

      file = {
        source = jsonSource "${storeKey}-${lib.removePrefix "." storeFilename}" content;

        onChange = lib.mkIf cfg.mutableProfile ''
          echo "Regenerating ${storeKey} file from source: '${storeFilename}${fileExtension}' -> '${sourceFilename}${fileExtension}'"

          run cp -vf "${storeFilePath}" "${sourceFilePath}"
        '';
      };
    in
    lib.nameValuePair storeFilePath file;
}
