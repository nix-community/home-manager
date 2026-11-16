{ lib, pkgs, ... }:

let
  staticSettings = builtins.toFile "managed.json" ''{"managed":true}'';
  original = builtins.toFile "original.json" ''{"user":true}'';
  concurrent = builtins.toFile "concurrent.json" ''{"newer":true}'';

  # The public reader input lets a writer change the target after the snapshot
  # is read, without timing-dependent sleeps or a hook in the merger. It also
  # rejects paths without the target's extension, as format-sniffing readers
  # such as yq would misread them.
  reader = pkgs.writeShellScript "concurrent-reader" ''
    set -euo pipefail
    [[ "$1" == *.json ]] || { echo "unexpected reader path: $1" >&2; exit 1; }
    ${lib.getExe pkgs.jaq} -c '.' "$1"
    if [[ ! -e "$TEST_DIRECTORY/mutated" ]]; then
      touch "$TEST_DIRECTORY/mutated"
      case "$MUTATION" in
        content|create)
          cat ${concurrent} > "$TEST_DIRECTORY/settings.json"
          ;;
        mode)
          chmod 600 "$TEST_DIRECTORY/settings.json"
          ;;
        retarget)
          ln -s "$TEST_DIRECTORY/other.json" "$TEST_DIRECTORY/new-link"
          mv -fT "$TEST_DIRECTORY/new-link" "$TEST_DIRECTORY/settings.json"
          ;;
        replace-link)
          cp ${concurrent} "$TEST_DIRECTORY/new-file"
          mv -fT "$TEST_DIRECTORY/new-file" "$TEST_DIRECTORY/settings.json"
          ;;
        same-target)
          ln -s "$TEST_DIRECTORY/resolved.json" "$TEST_DIRECTORY/new-link"
          mv -fT "$TEST_DIRECTORY/new-link" "$TEST_DIRECTORY/settings.json"
          ;;
        fail)
          exit 1
          ;;
      esac
    fi
  '';

  mkScript =
    name: options:
    pkgs.writeScript name ''
      set -euo pipefail
      errorEcho() { echo "$*" >&2; }
      trap 'touch "$TEST_DIRECTORY/outer-trap"' EXIT
      ${lib.hm.generators.mkImpureConfigMerger (
        {
          inherit pkgs staticSettings;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = "/@TMPDIR@/merger-write/settings.json";
        }
        // options
      )}
    '';
  merge = mkScript "merge-write" { };
  racingMerge = mkScript "merge-racing-write" { reader = lib.escapeShellArg reader; };
in
{
  nmt.script = ''
    substitute ${merge} "$TMPDIR/merge" --subst-var TMPDIR
    substitute ${racingMerge} "$TMPDIR/racing-merge" --subst-var TMPDIR
    chmod +x "$TMPDIR/merge" "$TMPDIR/racing-merge"
    export TEST_DIRECTORY="$TMPDIR/merger-write"
    mkdir -p "$TEST_DIRECTORY"
    settings="$TEST_DIRECTORY/settings.json"
    resolved="$TEST_DIRECTORY/resolved.json"

    assertClean() {
      if find "$TEST_DIRECTORY" -name '*.candidate.*' -o -name '*.snapshot.*' | grep -q .; then
        fail "Merger left temporary files behind"
      fi
      assertFileExists "$TEST_DIRECTORY/outer-trap"
      rm "$TEST_DIRECTORY/outer-trap"
    }
    expectFailure() {
      if "$@" > "$TMPDIR/failure.log" 2>&1; then
        fail "Merge should fail"
      fi
      assertClean
    }

    "$TMPDIR/merge"
    assertClean
    rm "$settings"
    cat ${original} > "$resolved"
    chmod 640 "$resolved"
    ln -s "$resolved" "$settings"
    inode="$(stat -c '%i' "$resolved")"
    "$TMPDIR/merge"
    [[ -L "$settings" ]] || fail "Merge replaced the symlink"
    [[ "$(stat -c '%i' "$resolved")" != "$inode" ]] || fail "Merge rewrote the target in place"
    [[ "$(stat -c '%a' "$resolved")" == 640 ]] || fail "Resolved mode changed"
    ${lib.getExe pkgs.jaq} -e '.managed == true and .user == true' "$resolved" > /dev/null
    assertClean

    # A dangling symlink is written through and keeps pointing at its target.
    rm "$settings"
    ln -s "$TEST_DIRECTORY/missing.json" "$settings"
    "$TMPDIR/merge"
    [[ "$(readlink "$settings")" == "$TEST_DIRECTORY/missing.json" ]] || fail "Dangling symlink was replaced"
    ${lib.getExe pkgs.jaq} -e '.managed == true' "$TEST_DIRECTORY/missing.json" > /dev/null
    assertClean
    rm "$TEST_DIRECTORY/missing.json"

    # A symlink into a missing directory still fails without changing it.
    rm "$settings"
    ln -s "$TEST_DIRECTORY/missing-dir/settings.json" "$settings"
    expectFailure "$TMPDIR/merge"
    [[ "$(readlink "$settings")" == "$TEST_DIRECTORY/missing-dir/settings.json" ]] || fail "Symlink was changed"
    assertPathNotExists "$TEST_DIRECTORY/missing-dir"

    rm "$settings"
    ln -s ${original} "$settings"
    expectFailure "$TMPDIR/merge"
    grep -q 'Nix store' "$TMPDIR/failure.log" || fail "Expected Nix store diagnostic"
    [[ "$(readlink "$settings")" == ${original} ]] || fail "Store symlink changed"

    rm "$settings"
    cat ${original} > "$settings"
    export MUTATION=none
    "$TMPDIR/racing-merge"
    ${lib.getExe pkgs.jaq} -e '.managed == true and .user == true' "$settings" > /dev/null
    assertClean

    rm "$TEST_DIRECTORY/mutated"
    cat ${original} > "$settings"
    chmod 644 "$settings"
    export MUTATION=mode
    expectFailure "$TMPDIR/racing-merge"
    grep -q 'changed during activation' "$TMPDIR/failure.log" || fail "Expected mode conflict"
    assertFileContent "$settings" ${original}
    [[ "$(stat -c '%a' "$settings")" == 600 ]] || fail "Concurrent mode change was reverted"

    rm "$TEST_DIRECTORY/mutated"
    cat ${original} > "$settings"
    export MUTATION=content
    expectFailure "$TMPDIR/racing-merge"
    grep -q 'changed during activation' "$TMPDIR/failure.log" || fail "Expected conflict diagnostic"
    assertFileContent "$settings" ${concurrent}

    rm "$TEST_DIRECTORY/mutated" "$settings"
    export MUTATION=create
    expectFailure "$TMPDIR/racing-merge"
    assertFileContent "$settings" ${concurrent}

    for mutation in retarget replace-link; do
      rm -f "$TEST_DIRECTORY/mutated" "$settings"
      cat ${original} > "$resolved"
      cat ${concurrent} > "$TEST_DIRECTORY/other.json"
      ln -s "$resolved" "$settings"
      export MUTATION="$mutation"
      expectFailure "$TMPDIR/racing-merge"
      grep -q 'changed during activation' "$TMPDIR/failure.log" || fail "Expected symlink conflict"
      assertFileContent "$resolved" ${original}
      if [[ "$mutation" == replace-link ]]; then
        [[ ! -L "$settings" ]] || fail "Replacement file was changed"
        assertFileContent "$settings" ${concurrent}
      elif [[ "$mutation" == retarget ]]; then
        [[ "$(readlink "$settings")" == "$TEST_DIRECTORY/other.json" ]] || fail "Retargeted link changed"
        assertFileContent "$settings" ${concurrent}
      fi
    done

    # The reader sees the configured file name even when the link points at a
    # file without the extension.
    rm -f "$TEST_DIRECTORY/mutated" "$settings"
    cat ${original} > "$TEST_DIRECTORY/current"
    ln -s "$TEST_DIRECTORY/current" "$settings"
    export MUTATION=none
    "$TMPDIR/racing-merge"
    [[ "$(readlink "$settings")" == "$TEST_DIRECTORY/current" ]] || fail "Symlink was changed"
    ${lib.getExe pkgs.jaq} -e '.managed == true and .user == true' "$TEST_DIRECTORY/current" > /dev/null
    assertClean
    rm "$TEST_DIRECTORY/current"

    # Replacing the link with an identical one changes nothing that matters.
    rm -f "$TEST_DIRECTORY/mutated" "$settings"
    cat ${original} > "$resolved"
    ln -s "$resolved" "$settings"
    export MUTATION=same-target
    "$TMPDIR/racing-merge"
    [[ "$(readlink "$settings")" == "$resolved" ]] || fail "Same-target link changed"
    ${lib.getExe pkgs.jaq} -e '.managed == true and .user == true' "$resolved" > /dev/null
    assertClean

    rm -f "$settings" "$TEST_DIRECTORY/mutated"
    cat ${original} > "$settings"
    export MUTATION=fail
    expectFailure "$TMPDIR/racing-merge"
    assertFileContent "$settings" ${original}

    rm "$settings"
    DRY_RUN=1 VERBOSE=1 "$TMPDIR/merge" > "$TMPDIR/dry-run.log"
    assertPathNotExists "$settings"
    grep -q 'Would merge' "$TMPDIR/dry-run.log" || fail "Expected dry-run output"
    grep -q 'Merging Nix-generated' "$TMPDIR/dry-run.log" || fail "Expected verbose output"
    assertClean
  '';
}
