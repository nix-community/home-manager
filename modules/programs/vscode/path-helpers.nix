{
  cfg,
  lib,
  pkgs,
}:
rec {
  setHasValue = attrs: key: (attrs ? "${key}") && (attrs.${key} != null);

  # App Config directory - also where extensions are stored
  #
  mkAppConfigDir = cfg.configDirectory;

  # https://code.visualstudio.com/docs/configure/settings#_settings-precedence
  # https://code.visualstudio.com/docs/configure/settings#_settings-json-file
  #
  # App User directory
  #
  mkAppUserDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${cfg.userDirectory}/User"
    else
      ".config/${cfg.userDirectory}/User";

  # Build a function to compute profile-scoped config paths
  #
  # Example usage:
  #   mkProfilePathBuilder "default" "settings"
  #
  mkProfilePathBuilder =
    profileName: key:
    lib.concatStringsSep "/" (
      [
        (if (setHasValue cfg.overridePaths key) then cfg.overridePaths.${key} else mkAppUserDir)
      ]
      ++ lib.optionals (profileName != "default") [ "profiles/${profileName}" ]
    );

  # Build a function to compute profile-scoped config paths for a given key
  #
  # Example usage:
  #   mkProfileConfigPathBuilder "default" "settings" cfg.mutableProfile
  #
  # If mutable is true, the path will be an immutable path that is enforced by the nix store
  # and the mutable path will be regenerated whenever the configuration for the profile is changed.
  #
  # This happens only during activation via the `onChange` hook.
  #
  mkProfileConfigPathBuilder =
    profileName: key: immutable:
    if immutable then
      builtins.trace "Building ${profileName}/.${key}-immutable.json" (
        mkProfilePathBuilder profileName key + "/.${key}-immutable.json"
      )
    else
      builtins.trace "Building ${profileName}/${key}.json" (
        mkProfilePathBuilder profileName key + "/${key}.json"
      );

  mkImmutableConfigPath = profileName: key: mkProfileConfigPathBuilder profileName key true;
  mkMutableConfigPath = profileName: key: mkProfileConfigPathBuilder profileName key false;

}
