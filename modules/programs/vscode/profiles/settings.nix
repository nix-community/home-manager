{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  inherit (import ../path-helpers.nix inputs)
    getAttrKey
    hasValue
    isCursorMcp
    isDefaultProfile
    isStorePath
    mkConfigFile
    settingsDirectory
    ;

  hasDefaultProfile = cfg.profiles ? default;
  defaultProfile = if hasDefaultProfile then cfg.profiles.default else { };
  otherProfiles = lib.removeAttrs cfg.profiles [ "default" ];

  buildProfile =
    profileName: profile:
    let
      isDefaultProfile = profileName == "default";

      # cursor mcp settings are only valid for default profile
      #
      isValidConfig =
        configKey: configValue:
        if isCursorMcp configKey && !isDefaultProfile then false else hasValue configValue;

      profileConfigs = lib.filterAttrs isValidConfig profile;

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
          configValue;
    in
    {
      files = lib.mapAttrs' buildConfig profileConfigs;
    };

  configFiles = lib.map (profile: profile.files) (lib.mapAttrsToList buildProfile cfg.profiles);
}
