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
          # store and path files cannot be modified, we can only modify object values that will
          # be persisted in the store by this module.  the user must manage settings in the
          # source file manually.
          #
          canUpdateConfig = !(isStorePath configValue);

          # update checks/notifications are set for default profile only but apply to all profiles
          #
          disableUpdateCheck = (getAttrKey "enableUpdateCheck" profile) == false;
          disableExtensionUpdateCheck = (getAttrKey "enableExtensionUpdateCheck" profile) == false;
        in
        if canUpdateConfig && isDefaultProfile && configKey == "settings" then
          configValue
          // lib.optionalAttrs (disableUpdateCheck) { "update.mode" = "none"; }
          // lib.optionalAttrs (disableExtensionUpdateCheck) { "extensions.autoCheckUpdates" = false; }
        else
          configValue;
    in
    {
      files = lib.mapAttrs' buildConfig profileConfigs;
    };

  configFiles = lib.map (profile: profile.files) (lib.mapAttrsToList buildProfile cfg.profiles);
}
