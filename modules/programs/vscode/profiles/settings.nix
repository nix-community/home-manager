{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  inherit (import ../path-helpers.nix inputs)
    hasValue
    isCursorMcp
    isDefaultProfile
    mkConfigFile
    settingsDirectory
    ;

  hasDefaultProfile = cfg.profiles ? default;
  defaultProfile = if hasDefaultProfile then cfg.profiles.default else { };
  otherProfiles = lib.removeAttrs cfg.profiles [ "default" ];

  buildProfile =
    profileName: profile:
    let
      isValidConfig =
        configKey: configValue:
        if isCursorMcp configKey && !isDefaultProfile profileName then false else hasValue configValue;

      profileConfigs = lib.filterAttrs isValidConfig profile;

      configStoreDirectory = settingsDirectory profileName;
      storeKey = "profile-${profileName}-settings";
    in
    {
      files = lib.mapAttrs' (
        sourceFilename: content:
        mkConfigFile {
          inherit
            content
            sourceFilename
            storeKey
            ;

          storeDirectory = configStoreDirectory sourceFilename;
        }
      ) profileConfigs;
    };

  configFiles = lib.map (profile: profile.files) (lib.mapAttrsToList buildProfile cfg.profiles);
}
