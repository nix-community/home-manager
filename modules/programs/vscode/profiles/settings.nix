{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  helpers = import ../path-helpers.nix inputs;

  inherit (cfg) homeDirectory mutableProfile packageName;
  inherit (helpers)
    getAttrKey
    hasAttrKey
    hasValue
    jsonSource
    profileDirectory
    settingsDirectory
    ;

  defaultProfile = if cfg.profiles ? default then cfg.profiles.default else { };
  otherProfiles = lib.removeAttrs cfg.profiles [ "default" ];

  hasDefaultProfile = cfg.profiles ? default;

  settingsKeys = [
    "keybindings"
    "settings"
    "tasks"
    "mcp"
  ];

  isCursorMcp = profileName: cfg.packageName == "code-cursor" && profileName == "default";

  profileConfigs =
    profileName: profile:
    let
      isCursor = cfg.packageName == "code-cursor";
      isDefaultProfile = profileName == "default";

      # if not cursor: include all settings
      # if cursor && default profile: include all settings
      # if cursor && other profile: include all settings except mcp
      #
      includeConfig = (!isCursor) || isDefaultProfile;
    in
    lib.filterAttrs (_: value: hasValue value) (
      lib.mapAttrs' (
        configName: _:
        lib.nameValuePair configName (lib.optionalAttrs includeConfig (getAttrKey configName profile))
      ) profile
    );

  profileConfigFiles =
    profileName: profile:
    lib.mapAttrs' (
      configName: configValue:
      let
        storeDir = "${toString (settingsDirectory profileName configName)}";

        sourceFilename = "${configName}.json";
        storeFilename = "${lib.optionalString mutableProfile ".immutable-"}${sourceFilename}";

        configFile = {
          source = jsonSource "${profileName}-user-${configName}" configValue;
          onChange = lib.mkIf mutableProfile ''
            echo "Regenerating settings file from immutable store: ${storeFilename} -> ${sourceFilename}"

            run cp -vf "$HOME/${storeDir}/${storeFilename}" "$HOME/${storeDir}/${sourceFilename}"
          '';
        };
      in
      lib.nameValuePair "${storeDir}/${storeFilename}" configFile
    ) (profileConfigs profileName profile);

  profileSettingsKeys =
    profile: lib.filter (settingsKey: hasAttrKey settingsKey profile) settingsKeys;

  # Cursor stores a single MCP configuration in ~/.cursor/mcp.json for all profiles
  #
  # For files other than the cursor MCP config, generate files for all profiles.
  # For the cursor MCP config, restrict file generation to the default profile only,
  # to avoid nix store conflicts.
  #
  # others -> [global: [], profiles: [keybindings, settings, tasks, mcp]]
  # cursor -> [global: [mcp], profiles: [keybindings, settings, tasks]]

  profileSettingsFiles =
    profileName: profile:
    builtins.trace
      "[profileConfigFiles.${profileName}] ${
        lib.generators.toPretty { } ((profileConfigFiles profileName profile))
      }"
      lib.filterAttrs
      (filename: file: file != null && file != { })
      (
        lib.listToAttrs (
          lib.map (
            settingsKey:
            let
              storeDir = "${toString (settingsDirectory profileName settingsKey)}";

              sourceFilename = settingsKey;
              storeFilename = "${lib.optionalString mutableProfile ".immutable-"}${settingsKey}";

              settingsFile = {
                source = jsonSource "${profileName}-user-${settingsKey}" profile.${settingsKey};
                onChange = lib.mkIf mutableProfile ''
                  echo "Regenerating file from source: ${storeFilename}.json -> ${sourceFilename}.json"

                  run cp -vf "$HOME/${storeDir}/${storeFilename}.json" \
                              "$HOME/${storeDir}/${sourceFilename}.json"
                '';
              };
            in
            lib.nameValuePair "${storeDir}/${storeFilename}.json" (lib.mkIf (storeDir != "") settingsFile)
          ) (profileSettingsKeys profile)
        )
      );
}
