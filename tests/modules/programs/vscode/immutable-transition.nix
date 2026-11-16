package:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  userPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User"
    else
      ".config/Code/User";
  settingsPath = "${userPath}/settings.json";
  disabledSettingsPath = "${userPath}/profiles/disabled/settings.json";
in
{
  programs.vscode = {
    enable = true;
    inherit package;
    mutableExtensionsDir = false;
    profiles.default = {
      mutableUserSettings = false;
      userSettings.transition = "immutable";
    };
    profiles.disabled = {
      mutableUserSettings = false;
      userSettings.transition = "immutable";
    };
  };

  home.file."${config.home.homeDirectory}/${disabledSettingsPath}".enable = false;

  assertions = [
    {
      assertion = config.home.activation.vscodeImmutableUserSettings.after == [ "writeBoundary" ];
      message = "Immutable VSCode settings cleanup must run after writeBoundary.";
    }
    {
      assertion = config.home.activation.vscodeImmutableUserSettings.before == [ "linkGeneration" ];
      message = "Immutable VSCode settings cleanup must run before linkGeneration.";
    }
    {
      assertion =
        !lib.hasInfix disabledSettingsPath config.home.activation.vscodeImmutableUserSettings.data;
      message = "Disabled VSCode settings files must not register cleanup.";
    }
    {
      assertion = !(config.home.activation ? vscodeMutableUserSettings);
      message = "Immutable VSCode profiles must not register mutable settings activation.";
    }
  ];

  nmt.script = ''
    assertFileContent "home-files/${settingsPath}" ${./vscode-immutable-expected.json}
    assertPathNotExists "home-files/${disabledSettingsPath}"
    assertFileContains activate '${settingsPath}'
  '';
}
