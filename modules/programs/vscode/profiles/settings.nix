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
    mkConfigFilePair
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

      buildConfigFile =
        configKey: configValue:
        mkConfigFilePair profileName (settingsDirectory profileName configKey) configKey configValue;

      # debugging helpers for tracing
      #
      # profileConfigFiles = lib.mapAttrs' mkConfigFile profileAttrs;
      # validProfileConfigKeys = lib.attrNames profileAttrs;
    in
    {
      files = lib.mapAttrs' buildConfigFile profileConfigs;
    };

  configFiles = lib.map (profile: profile.files) (lib.mapAttrsToList buildProfile cfg.profiles);
}
