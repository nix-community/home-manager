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
  workSettingsPath = "${userPath}/profiles/work/settings.json";
  missingSettingsPath = "${userPath}/profiles/missing/settings.json";
  emptySettingsPath = "${userPath}/profiles/empty/settings.json";
in
{
  programs.vscode = {
    enable = true;
    inherit package;
    mutableExtensionsDir = false;
    profiles = {
      default = {
        mutableUserSettings = true;
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        userSettings = {
          "editor.fontSize" = 14;
          arraySetting = [ "declared" ];
          nested = {
            declared = "from-nix";
            added = true;
            deeper.declared = "from-nix";
          };
        };
      };

      work = {
        mutableUserSettings = true;
        userSettings = ./mutable-settings-path.jsonc;
      };

      missing = {
        mutableUserSettings = true;
        userSettings.created = true;
      };

      empty.mutableUserSettings = true;
    };
  };

  assertions = [
    {
      assertion = !lib.hasInfix emptySettingsPath config.home.activation.vscodeMutableUserSettings.data;
      message = "Empty mutable VSCode settings must not register a settings operation.";
    }
    {
      assertion = config.home.activation.vscodeMutableUserSettings.after == [ "linkGeneration" ];
      message = "Mutable VSCode settings must activate after linkGeneration.";
    }
    {
      assertion = !(config.home.activation ? vscodeImmutableUserSettings);
      message = "Mutable profiles must not register immutable settings cleanup.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/${settingsPath}"
    assertFileContains activate '${config.home.homeDirectory}/${settingsPath}'
    assertPathNotExists "home-files/${workSettingsPath}"
    assertFileContains activate '${config.home.homeDirectory}/${workSettingsPath}'
    assertPathNotExists "home-files/${missingSettingsPath}"
    assertFileContains activate '${config.home.homeDirectory}/${missingSettingsPath}'
    assertPathNotExists "home-files/${emptySettingsPath}"
    default="$(grep -F "vscodeMutableSettings ${lib.escapeShellArg "${config.home.homeDirectory}/${settingsPath}"}" "$TESTED/activate" | grep -m1 -o "/nix/store/[^ ']*-vscode-user-settings")" \
      || fail "VSCode default settings input is missing from activation"
    assertFileContent "$default" ${./mutable-default-expected.json}
    work="$(grep -F "vscodeMutableSettings ${lib.escapeShellArg "${config.home.homeDirectory}/${workSettingsPath}"}" "$TESTED/activate" | grep -m1 -o "/nix/store/[^ ']*-vscode-user-settings-json5")" \
      || fail "VSCode work settings input is missing from activation"
    assertFileContent "$work" ${./mutable-work-expected.jsonc}
    missing="$(grep -F "vscodeMutableSettings ${lib.escapeShellArg "${config.home.homeDirectory}/${missingSettingsPath}"}" "$TESTED/activate" | grep -m1 -o "/nix/store/[^ ']*-vscode-user-settings")" \
      || fail "VSCode missing settings input is missing from activation"
    assertFileContent "$missing" ${./expectedMissing.json}
  '';
}
