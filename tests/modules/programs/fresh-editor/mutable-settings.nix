mode:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  customXdg = mode == "custom-xdg";
  hasSettings =
    !(lib.elem mode [
      "empty"
      "immutable-empty"
    ]);
  configDir =
    if customXdg && !pkgs.stdenv.hostPlatform.isDarwin then "config with spaces" else ".config";
  platformFile =
    if pkgs.stdenv.hostPlatform.isDarwin then "config_macos.json" else "config_linux.json";
  otherPlatformFile =
    if pkgs.stdenv.hostPlatform.isDarwin then "config_linux.json" else "config_macos.json";
in
{
  xdg.configHome = lib.mkIf customXdg "${config.home.homeDirectory}/config with spaces";

  programs.fresh-editor = {
    enable = mode != "disabled";
    mutableSettings = mode != "immutable-empty";
    settings = lib.optionalAttrs hasSettings (builtins.fromJSON (builtins.readFile ./config.json));
  };

  nmt.script = ''
    assertPathNotExists "home-files/${configDir}/fresh/config.json"
    assertPathNotExists "home-files/${configDir}/fresh/${otherPlatformFile}"
  ''
  + (
    if hasSettings && mode != "disabled" then
      ''
        assertFileContent "home-files/${configDir}/fresh/${platformFile}" ${./config.json}
      ''
    else
      ''
        assertPathNotExists "home-files/${configDir}/fresh/${platformFile}"
      ''
  )
  + lib.optionalString customXdg ''
    assertPathNotExists "home-files/${
      if pkgs.stdenv.hostPlatform.isDarwin then "config with spaces" else ".config"
    }/fresh"
  '';
}
