{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:

let
  inherit (lib) escapeShellArg mkForce;
  inherit (pkgs) stdenv writeScript writeText;

  settingsPath =
    (if stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".local/share")
    + "/PrismLauncher/prismlauncher.cfg";

  existingSettings = writeText "prismlauncher-existing.cfg" ''
    [General]
    ApplicationTheme=system
    MaxMemAlloc=8192
    MinMemAlloc=512
  '';

  expectedSettings = writeText "prismlauncher-expected.cfg" ''
    [General]
    ApplicationTheme=dark
    MaxMemAlloc=8192
    MinMemAlloc=512
    ConsoleMaxLines=100000
    ShowConsole=true
  '';

  activationScript = writeScript "configurePrismLauncher" config.home.activation.configurePrismLauncher.data;
in

{
  programs.prismlauncher = {
    enable = true;

    settings = {
      ApplicationTheme = "dark";
      ShowConsole = true;
      ConsoleMaxLines = 100000;
    };
  };

  home.homeDirectory = mkForce "/@TMPDIR@/hm-user";

  # activation script depends on crudini to merge settings
  test.unstubs = [ (_self: _super: { inherit (realPkgs) crudini; }) ];

  nmt.script = ''
    export HOME="$TMPDIR"/hm-user

    settingsPath=~/${escapeShellArg settingsPath}
    existingFile=${existingSettings}
    expectedFile=${expectedSettings}

    # write existing config
    mkdir -p "$(dirname "$settingsPath")"
    cat "$existingFile" > "$settingsPath"

    # validate the existing config
    assertFileExists "$settingsPath"
    assertFileContent "$settingsPath" "$existingFile"

    # prepare the activation script
    substitute ${activationScript} ~/activate --subst-var TMPDIR
    chmod +x ~/activate

    # run the activation script
    ~/activate

    # validate the merged config
    assertFileExists "$settingsPath"
    assertFileContent "$settingsPath" "$expectedFile"

    # run the activation script AGAIN
    ~/activate

    # validate again to check idempotence
    assertFileExists "$settingsPath"
    assertFileContent "$settingsPath" "$expectedFile"
  '';
}
