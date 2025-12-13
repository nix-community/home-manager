{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  inherit (import ../path-helpers.nix inputs)
    getAttrKey
    hasValue
    isStorePath
    joinPaths
    mkConfigFile
    profileDirectory
    ;

  # Profile settings directory
  #
  #  - default profile: userDirectory
  #  - other profiles: userDirectory + /profiles/ + profileName
  #
  #  - examples:
  #
  #    - default:
  #      - mcp: ~/Library/Application Support/Code/User/mcp.json
  #      - settings: ~/Library/Application Support/Code/User/settings.json
  #    - work:
  #      - mcp: ~/Library/Application Support/Code/User/profiles/work/mcp.json
  #      - tasks: ~/Library/Application Support/Code/User/profiles/work/tasks.json
  #
  #   - notes:
  #     - cursor MCP configuration is a single profile setting (instead of per profile) and it's
  #       stored in the dataFolderDirectory instead of the userDirectory
  #
  settingsDirectory =
    profileName: configKey:
    if (isCursorMcpConfigKey configKey) && (isDefaultProfile profileName) then
      joinPaths [
        cfg.homeDirectory
        cfg.dataFolderName
      ]
    else
      (profileDirectory profileName);

  hasDefaultProfile = cfg.profiles ? default;
  defaultProfile = if hasDefaultProfile then cfg.profiles.default else { };
  otherProfiles = lib.removeAttrs cfg.profiles [ "default" ];

  isDefaultProfile = profileName: profileName == "default";
  isCursorMcpConfigKey = configKey: cfg.package.pname == "cursor" && configKey == "mcp";

  profileConfigKeys = [
    "keybindings"
    "mcp"
    "settings"
    "tasks"
  ];

  profileConfigs =
    profileName: profile:
    let
      isValidProfileConfig =
        configKey: configValue:
        # must be a valid configKey this module supports
        (builtins.elem configKey profileConfigKeys)
        # remove cursor mcp config key if not the default profile
        && !(isCursorMcpConfigKey configKey && !isDefaultProfile profileName)
        # all other config keys are valid for all profiles if they have a non-empty/non-null value
        && (hasValue configValue);
    in
    lib.filterAttrs isValidProfileConfig profile;

  buildProfile =
    profileName: profile:
    let
      getProfileConfigs = profileConfigs profileName profile;
      configStoreDirectory = settingsDirectory profileName;

      storeKey = "profile-${profileName}-settings";

      buildConfig =
        configKey: configValue:
        mkConfigFile {
          inherit storeKey;

          sourceFilename = configKey;
          storeDirectory = configStoreDirectory configKey;

          content = buildConfigContent configKey configValue;
        };

      buildConfigContent =
        configKey: configValue:
        let
          value = if (isStorePath configValue) then lib.importJSON configValue else configValue;

          # update checks/notifications are set for default profile only but apply to all profiles
          #
          disableUpdateCheck = (getAttrKey "enableUpdateCheck" profile) == false;
          disableExtensionUpdateCheck = (getAttrKey "enableExtensionUpdateCheck" profile) == false;
        in
        if (configKey == "settings") && (isDefaultProfile profileName) then
          value
          // lib.optionalAttrs (disableUpdateCheck) { "update.mode" = "none"; }
          // lib.optionalAttrs (disableExtensionUpdateCheck) { "extensions.autoCheckUpdates" = false; }
        else if (configKey == "mcp") then
          let
            mcpKey = if cfg.package.pname == "cursor" then "mcpServers" else "servers";

            mcpServers = if value ? ${mcpKey} then value.${mcpKey} else { };
          in
          {
            ${mcpKey} = cfg.globalMcpServers // mcpServers;
          }
        else
          value;
    in
    {
      files = lib.mapAttrs' buildConfig getProfileConfigs;
    };

  configFiles = lib.map (profile: profile.files) (lib.mapAttrsToList buildProfile cfg.profiles);
}
