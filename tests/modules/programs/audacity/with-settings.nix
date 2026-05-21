{
  config,
  lib,
  pkgs,
  ...
}:

let
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/audacity/audacity.cfg"
    else
      ".config/audacity/audacity.cfg";
  preexistingConfig = pkgs.writeText "preexisting.cfg" ''
    [Version]
    Version=3.7.7

    [GUI]
    ShowSplashScreen=1
    WindowMaximized=1
  '';
  generatedConfig = pkgs.writeText "generated.cfg" ''
    PrefsVersion=1.1.0.0

    [AudioIO]
    DefaultSampleRate=44100
    SWPlaythrough=0

    [GUI]
    ShowSplashScreen=0
    Theme=classic
  '';
  expectedConfig = pkgs.writeText "expected.cfg" ''
    PrefsVersion=1.1.0.0
    [Version]
    Version=3.7.7

    [GUI]
    ShowSplashScreen=0
    WindowMaximized=1
    Theme=classic

    [AudioIO]
    DefaultSampleRate=44100
    SWPlaythrough=0
  '';
  activationScript = pkgs.writeScript "activation" config.home.activation.audacitySettings.data;
in
{
  programs.audacity = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "3.7.7"; };
    settings = {
      globalSection.PrefsVersion = "1.1.0.0";
      sections = {
        AudioIO = {
          DefaultSampleRate = "44100";
          SWPlaythrough = false;
        };
        GUI = {
          ShowSplashScreen = false;
          Theme = "classic";
        };
      };
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    run() {
      if [[ "''${DRY_RUN:-0}" == 1 ]]; then
        return 0
      fi
      "$@"
    }
    export -f run

    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    chmod +x $TMPDIR/activate
    $TMPDIR/activate
    assertFileContent "$HOME/${settingsPath}" "${generatedConfig}"

    mkdir -p "$HOME/$(dirname "${settingsPath}")"
    cat ${preexistingConfig} > "$HOME/${settingsPath}"
    $TMPDIR/activate

    assertFileExists "$HOME/${settingsPath}"
    assertFileContent "$HOME/${settingsPath}" "${expectedConfig}"

    cat ${preexistingConfig} > "$HOME/${settingsPath}"
    DRY_RUN=1 $TMPDIR/activate
    assertFileContent "$HOME/${settingsPath}" "${preexistingConfig}"

    $TMPDIR/activate
    assertFileContent "$HOME/${settingsPath}" "${expectedConfig}"
  '';
}
