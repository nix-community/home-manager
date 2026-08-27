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
  malformedSettingsPath = "${userPath}/profiles/malformed/settings.json";
  relativeSettingsPath = "${userPath}/profiles/relative/settings.json";
  relativeSettingsTarget = "${userPath}/relative-settings.json";
  appearingSettingsPath = "${userPath}/profiles/appearing/settings.json";
  danglingSettingsPath = "${userPath}/profiles/z-dangling/settings.json";
  emptySettingsPath = "${userPath}/profiles/empty/settings.json";
  activationScript = pkgs.writeShellScript "activation" ''
    set -eu
    set -o pipefail
    ${config.lib.bash.initHomeManagerLib}
    ${config.home.activation.vscodeMutableUserSettings.data}
  '';
  jq = lib.getExe pkgs.jq;
  sed = lib.getExe pkgs.gnused;
  stat = lib.getExe' pkgs.coreutils "stat";
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

      malformed = {
        mutableUserSettings = true;
        userSettings.recovered = true;
      };

      relative = {
        mutableUserSettings = true;
        userSettings.declared = "through-link";
      };

      appearing = {
        mutableUserSettings = true;
        userSettings.declared = "from-nix";
      };

      z-dangling = {
        mutableUserSettings = true;
        userSettings.declared = "from-nix";
      };

      empty.mutableUserSettings = true;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    set -eu
    set -o pipefail

    export HOME=$TMPDIR/hm-user

    mkdir -p "$HOME/${userPath}/profiles/work"
    mkdir -p "$HOME/${userPath}/profiles/malformed"
    mkdir -p "$HOME/${userPath}/profiles/relative"
    cp ${./mutable-settings-live.json5} "$HOME/${settingsPath}"
    cp ${./mutable-settings-work-live.json5} "$HOME/${workSettingsPath}"
    printf '{ live: "through-relative-link" }\n' > "$HOME/${relativeSettingsTarget}"
    ln -s ../../relative-settings.json "$HOME/${relativeSettingsPath}"
    printf ' \n\t\n' > "$HOME/${malformedSettingsPath}"
    chmod 0640 "$HOME/${settingsPath}"
    chmod 0604 "$HOME/${workSettingsPath}"
    chmod 0644 "$HOME/${malformedSettingsPath}"

    ${sed} "s|/@TMPDIR@|$TMPDIR|g" ${activationScript} > $TMPDIR/activate
    chmod +x $TMPDIR/activate

    cp "$HOME/${settingsPath}" $TMPDIR/default-settings-before-dry-run
    cp "$HOME/${workSettingsPath}" $TMPDIR/work-settings-before-dry-run
    cp "$HOME/${malformedSettingsPath}" $TMPDIR/malformed-settings-before-dry-run
    relative_link_before_dry_run="$(readlink "$HOME/${relativeSettingsPath}")"

    DRY_RUN=1 $TMPDIR/activate > $TMPDIR/dry-run-output

    cmp $TMPDIR/default-settings-before-dry-run "$HOME/${settingsPath}"
    cmp $TMPDIR/work-settings-before-dry-run "$HOME/${workSettingsPath}"
    cmp $TMPDIR/malformed-settings-before-dry-run "$HOME/${malformedSettingsPath}"
    test "$(readlink "$HOME/${relativeSettingsPath}")" = "$relative_link_before_dry_run"
    assertPathNotExists "$HOME/${userPath}/profiles/missing"
    grep -F "mkdir -p $HOME/${userPath}/profiles/missing" $TMPDIR/dry-run-output
    grep -F "Would update Visual Studio Code settings at '$HOME/${missingSettingsPath}'" $TMPDIR/dry-run-output
    test -z "$(find "$HOME/${userPath}" \
      \( -name 'settings.json.snapshot.*' -o -name 'settings.json.candidate.*' \) \
      -print -quit)"

    VERBOSE=1 $TMPDIR/activate > $TMPDIR/verbose-output

    grep -F "Merging declared Visual Studio Code settings into '$HOME/${settingsPath}'" \
      $TMPDIR/verbose-output

    assertPathNotExists "home-files/${settingsPath}"
    assertPathNotExists "home-files/${workSettingsPath}"
    test ! -L "$HOME/${settingsPath}"
    test ! -L "$HOME/${workSettingsPath}"
    test -L "$HOME/${relativeSettingsPath}"
    test "$(readlink "$HOME/${relativeSettingsPath}")" = ../../relative-settings.json
    test -w "$HOME/${settingsPath}"
    test -w "$HOME/${workSettingsPath}"
    test "$(${stat} -c %a "$HOME/${settingsPath}")" = 640
    test "$(${stat} -c %a "$HOME/${workSettingsPath}")" = 604

    ${jq} -e '
      .["editor.fontSize"] == 14 and
      .arraySetting == ["declared"] and
      .nested.declared == "from-nix" and
      .nested.added == true and
      .nested.keep == true and
      .nested.deeper.declared == "from-nix" and
      .nested.deeper.keep == "nested-live" and
      .unrelated == "survives" and
      .["update.mode"] == "none" and
      .["extensions.autoCheckUpdates"] == false
    ' "$HOME/${settingsPath}"

    ${jq} -e '
      .["editor.wordWrap"] == "on" and
      .nested.declared == "from-path" and
      .nested.pathOnly == true and
      .nested.liveOnly == true and
      .["workbench.colorTheme"] == "Interactive"
    ' "$HOME/${workSettingsPath}"

    ${jq} -e '. == {"created": true}' "$HOME/${missingSettingsPath}"
    ${jq} -e '. == {"recovered": true}' "$HOME/${malformedSettingsPath}"
    ${jq} -e '. == {"live": "through-relative-link", "declared": "through-link"}' \
      "$HOME/${relativeSettingsTarget}"
    assertPathNotExists "$HOME/${emptySettingsPath}"
    test -z "$(find "$HOME/${userPath}" \
      \( -name 'settings.json.snapshot.*' -o -name 'settings.json.candidate.*' \) \
      -print -quit)"

    cp "$HOME/${settingsPath}" $TMPDIR/default-settings-before
    cp "$HOME/${workSettingsPath}" $TMPDIR/work-settings-before
    cp "$HOME/${missingSettingsPath}" $TMPDIR/missing-settings-before
    cp "$HOME/${malformedSettingsPath}" $TMPDIR/malformed-settings-before

    $TMPDIR/activate

    cmp $TMPDIR/default-settings-before "$HOME/${settingsPath}"
    cmp $TMPDIR/work-settings-before "$HOME/${workSettingsPath}"
    cmp $TMPDIR/missing-settings-before "$HOME/${missingSettingsPath}"
    cmp $TMPDIR/malformed-settings-before "$HOME/${malformedSettingsPath}"

    cp ${./mutable-settings-malformed.json5} "$HOME/${malformedSettingsPath}"
    cp "$HOME/${malformedSettingsPath}" $TMPDIR/malformed-settings-before-failure

    if $TMPDIR/activate > $TMPDIR/malformed-output 2>&1; then
      echo "Activation unexpectedly accepted malformed JSON5" >&2
      exit 1
    fi

    grep -F "Cannot parse Visual Studio Code settings at '$HOME/${malformedSettingsPath}' as JSON5" $TMPDIR/malformed-output
    cmp $TMPDIR/malformed-settings-before-failure "$HOME/${malformedSettingsPath}"

    printf ' \n\t\n' > "$HOME/${malformedSettingsPath}"
    cp ${./mutable-settings-live.json5} "$HOME/${settingsPath}"

    if (
      CONCURRENT_WRITE_PATH="$HOME/${settingsPath}"
      chmod() {
        candidate_argument="''${!#}"
        if [[ $1 == --reference=* \
          && $candidate_argument == "$CONCURRENT_WRITE_PATH.candidate."* ]]; then
          command printf '{"concurrent": true}\n' > "$CONCURRENT_WRITE_PATH"
        fi
        command chmod "$@"
      }
      source $TMPDIR/activate
    ) > $TMPDIR/concurrent-output 2>&1; then
      echo "Activation unexpectedly replaced a concurrent settings update" >&2
      exit 1
    fi

    grep -F "Visual Studio Code settings at '$HOME/${settingsPath}' changed during activation" \
      $TMPDIR/concurrent-output
    ${jq} -e '. == {"concurrent": true}' "$HOME/${settingsPath}"

    rm -f "$HOME/${appearingSettingsPath}"

    if (
      APPEARING_PATH="$HOME/${appearingSettingsPath}"
      printf() {
        builtin printf "$@"
        if [[ -n ''${candidate_path-} \
          && $candidate_path == "$APPEARING_PATH.candidate."* ]]; then
          command printf '{"appeared": true}\n' > "$APPEARING_PATH"
        fi
      }
      source $TMPDIR/activate
    ) > $TMPDIR/appearing-output 2>&1; then
      echo "Activation unexpectedly replaced a settings file that appeared during activation" >&2
      exit 1
    fi

    grep -F "Visual Studio Code settings at '$HOME/${appearingSettingsPath}' changed during activation" \
      $TMPDIR/appearing-output
    ${jq} -e '. == {"appeared": true}' "$HOME/${appearingSettingsPath}"

    rm -f "$HOME/${danglingSettingsPath}"
    ln -s missing-target.json "$HOME/${danglingSettingsPath}"

    if $TMPDIR/activate > $TMPDIR/dangling-output 2>&1; then
      echo "Activation unexpectedly replaced a dangling settings symlink" >&2
      exit 1
    fi

    grep -F "Cannot resolve Visual Studio Code settings at '$HOME/${danglingSettingsPath}'" \
      $TMPDIR/dangling-output
    test -L "$HOME/${danglingSettingsPath}"
    test "$(readlink "$HOME/${danglingSettingsPath}")" = missing-target.json
    test ! -e "$HOME/${danglingSettingsPath}"
    test -z "$(find "$HOME/${userPath}" \
      \( -name 'settings.json.snapshot.*' -o -name 'settings.json.candidate.*' \) \
      -print -quit)"
  '';
}
