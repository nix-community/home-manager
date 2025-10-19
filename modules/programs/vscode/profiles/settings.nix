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
      storeKey = "profile-${profileName}-settings";

      isValidConfig =
        configKey: configValue:
        if isCursorMcp configKey && !isDefaultProfile profileName then false else hasValue configValue;

      profileConfigs = lib.filterAttrs isValidConfig profile;
    in
    {
      files = lib.mapAttrs' (
        sourceFilename: content:
        let
          storeDirectory = settingsDirectory profileName sourceFilename;
        in
        mkConfigFile {
          inherit
            storeKey
            storeDirectory
            sourceFilename
            content
            ;
        }
      ) profileConfigs;
    };

  configFiles = lib.map (profile: profile.files) (lib.mapAttrsToList buildProfile cfg.profiles);
}
