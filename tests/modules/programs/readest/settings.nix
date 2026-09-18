{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.readest = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "readest"; };
    settings = {
      telemetryEnabled = false;
      libraryViewMode = "grid";
      globalViewSettings = {
        theme = "dark";
        defaultFontSize = 18;
      };
      enabledPlugins = [ "dictionary" ];
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "readest-preexisting-settings.json" ''
        {
          "telemetryEnabled": true,
          "libraryViewMode": "list",
          "globalViewSettings": {
            "theme": "light",
            "lineHeight": 1.5
          },
          "appOwnedSetting": "preserved",
          "enabledPlugins": ["translator", "notes"]
        }
      '';

      expectedInitialSettings = builtins.toFile "readest-expected-initial-settings.json" ''
        {
          "enabledPlugins": [
            "dictionary"
          ],
          "globalViewSettings": {
            "defaultFontSize": 18,
            "theme": "dark"
          },
          "libraryViewMode": "grid",
          "telemetryEnabled": false
        }
      '';

      expectedMergedSettings = builtins.toFile "readest-expected-merged-settings.json" ''
        {
          "appOwnedSetting": "preserved",
          "enabledPlugins": [
            "dictionary"
          ],
          "globalViewSettings": {
            "defaultFontSize": 18,
            "lineHeight": 1.5,
            "theme": "dark"
          },
          "libraryViewMode": "grid",
          "telemetryEnabled": false
        }
      '';

      settingsPath = ".config/com.bilingify.readest/settings.json";
      activationScript = pkgs.writeScript "readest-settings-activation" (
        config.home.activation.readestSettings.data
      );
    in
    ''
      export HOME=$TMPDIR/hm-user
      export XDG_CONFIG_HOME=$HOME/.config

      substitute ${activationScript} $TMPDIR/readest-activate --subst-var TMPDIR
      chmod +x $TMPDIR/readest-activate
      function run() { "$@"; }
      function verboseEcho() { :; }
      function assertJsonEqual() {
        diff -u \
          <(${lib.getExe pkgs.jq} --sort-keys . "$1") \
          <(${lib.getExe pkgs.jq} --sort-keys . "$2")
      }

      source $TMPDIR/readest-activate
      assertJsonEqual "$HOME/${settingsPath}" "${expectedInitialSettings}"
      [[ "$(stat -c '%a' "$HOME/${settingsPath}")" == 600 ]] \
        || fail "Readest settings should have mode 600"

      cat ${preexistingSettings} > "$HOME/${settingsPath}"
      source $TMPDIR/readest-activate
      assertJsonEqual "$HOME/${settingsPath}" "${expectedMergedSettings}"

      source $TMPDIR/readest-activate
      assertJsonEqual "$HOME/${settingsPath}" "${expectedMergedSettings}"
    '';
}
