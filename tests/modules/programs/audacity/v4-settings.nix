{
  config,
  lib,
  pkgs,
  ...
}:

let
  settingsPath = ".config/Audacity/Audacity4.ini";
  preexistingConfig = pkgs.writeText "preexisting.ini" ''
    [General]
    KeepThis=true

    [application]
    checkForUpdate=true
  '';
  expectedConfig = pkgs.writeText "expected.ini" ''
    [General]
    KeepThis=true
    generalOption=enabled
    migrated=true

    [application]
    checkForUpdate=false
    launchOnStartup=true
  '';
  activationScript = pkgs.writeScript "activation" config.home.activation.audacitySettings.data;
in
{
  programs.audacity = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "4.0.0"; };
    settings = {
      globalSection.migrated = true;
      sections = {
        General.generalOption = "enabled";
        application = {
          checkForUpdate = false;
          launchOnStartup = true;
        };
      };
    };
    macros.example = [ { command = "SelectAll"; } ];
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
    mkdir -p "$HOME/$(dirname "${settingsPath}")"
    cat ${preexistingConfig} > "$HOME/${settingsPath}"

    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    assertFileExists "$HOME/${settingsPath}"
    assertFileContent "$HOME/${settingsPath}" "${expectedConfig}"
    [[ ! -e home-files/.local/share/audacity/Macros/example.txt ]]

    $TMPDIR/activate
    assertFileContent "$HOME/${settingsPath}" "${expectedConfig}"

    cat > "$HOME/${settingsPath}" <<'EOF'
    [General]
    KeepThis=true
    migrated=false
    generalOption=enabled

    [application]
    checkForUpdate=true
    launchOnStartup=true
    EOF
    DRY_RUN=1 $TMPDIR/activate
    assertFileContent "$HOME/${settingsPath}" ${builtins.toFile "dry-run.ini" ''
      [General]
      KeepThis=true
      migrated=false
      generalOption=enabled

      [application]
      checkForUpdate=true
      launchOnStartup=true
    ''}
  '';

  test.asserts.warnings.expected = [
    "programs.audacity.macros has no effect because Audacity 4 does not support macros."
  ];
  test.asserts.warnings.enable = true;
}
