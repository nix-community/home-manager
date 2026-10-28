# Tests for the activation-time static settings command of
# mkImpureConfigMerger.
{
  lib,
  pkgs,
  ...
}:

let
  mergeRuntimeStatic = pkgs.writeScript "merge-runtime-static" ''
    set -euo pipefail
    errorEcho() { echo "$*" >&2; }
    ${lib.hm.generators.mkImpureConfigMerger {
      inherit pkgs;
      format = "json";
      empty = "{}";
      jqOperation = "$dynamic * $static";
      path = "/@TMPDIR@/hm-user/.config/testmerger/settings.json";
      staticSettingsCommand = ''
        if [[ -v FAIL_STATIC ]]; then
          echo "static command failed" >&2
          exit 1
        fi
        touch "$STATIC_MARKER"
        printf '%s' "$(<"$STATIC_FILE")"
      '';
    }}
  '';

  original = builtins.toFile "original.json" ''{"user":true}'';
in
{
  nmt.script = ''
    substitute ${mergeRuntimeStatic} $TMPDIR/merge-runtime-static --subst-var TMPDIR
    chmod +x $TMPDIR/merge-runtime-static

    mkdir -p $TMPDIR/hm-user/.config/testmerger
    settings=$TMPDIR/hm-user/.config/testmerger/settings.json
    export STATIC_MARKER=$TMPDIR/static-command-ran

    # The static settings are produced only when activation merges them.
    printf '%s' '{"runtimeManaged":true}' > $TMPDIR/static.json
    export STATIC_FILE=$TMPDIR/static.json
    cat ${original} > $settings
    $TMPDIR/merge-runtime-static
    [[ -e $STATIC_MARKER ]] || fail "The static settings command was not run"
    ${lib.getExe pkgs.jaq} -e '.user == true and .runtimeManaged == true' $settings > /dev/null

    # Dry runs must not execute the command or read its source.
    rm -f $STATIC_MARKER
    export STATIC_FILE=$TMPDIR/missing.json
    DRY_RUN=1 $TMPDIR/merge-runtime-static > $TMPDIR/dry-run-output
    [[ ! -e $STATIC_MARKER ]] || fail "A dry run executed the static settings command"
    grep -qF 'Would merge Nix-generated config' $TMPDIR/dry-run-output \
      || fail "A dry run must report the merge"

    # A failing command must fail activation and keep the existing file.
    cat ${original} > $settings
    if FAIL_STATIC=1 $TMPDIR/merge-runtime-static 2> $TMPDIR/static-error; then
      fail "A failing static settings command must fail activation"
    fi
    assertFileContent $settings ${original}
    grep -qF 'Could not read Nix-generated config' $TMPDIR/static-error \
      || fail "A failed static settings command must produce a diagnostic"

    # Empty output is rejected instead of installing an empty config.
    cat ${original} > $settings
    export STATIC_FILE=/dev/null
    if $TMPDIR/merge-runtime-static 2> $TMPDIR/empty-error; then
      fail "Empty static settings must fail activation"
    fi
    assertFileContent $settings ${original}
    grep -qF 'Could not read Nix-generated config' $TMPDIR/empty-error \
      || fail "Empty static settings must produce a diagnostic"

    # Invalid JSON is rejected before replacing the existing config.
    cat ${original} > $settings
    printf '%s' '{not json}' > $TMPDIR/invalid-static.json
    export STATIC_FILE=$TMPDIR/invalid-static.json
    if $TMPDIR/merge-runtime-static 2> $TMPDIR/invalid-error; then
      fail "Invalid static settings must fail activation"
    fi
    assertFileContent $settings ${original}
    grep -qF 'Could not merge Nix-generated config' $TMPDIR/invalid-error \
      || fail "Invalid static settings must produce a diagnostic"
  '';
}
