{
  lib,
  pkgs,
  realPkgs,
  ...
}:
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  home.packages = [
    (realPkgs.callPackage ../../../../tools/managed-config/package.nix { })
  ];

  nmt.script = ''
    export HOME=$TMPDIR/hm-user

    mkdir -p "$TMPDIR/source" "$TMPDIR/live"
    cat > "$TMPDIR/source/settings.ini" <<'EOF'
    [General]
    Enabled=true
    EOF
    cat > "$TMPDIR/source/settings.json" <<'EOF'
    {
      "name": "demo",
      "secret_token": "drop-me",
      "nested": {
        "path": "/home/demo/file"
      }
    }
    EOF

    ini_hash="$(${pkgs.coreutils}/bin/sha256sum "$TMPDIR/source/settings.ini" | cut -d ' ' -f 1)"
    json_hash="$(${pkgs.coreutils}/bin/sha256sum "$TMPDIR/source/settings.json" | cut -d ' ' -f 1)"
    cat > "$TMPDIR/manifest.json" <<EOF
    {
      "version": 1,
      "module": "programs.demo",
      "files": [
        {
          "path": "settings.ini",
          "source": "$TMPDIR/source/settings.ini",
          "target": "$TMPDIR/live/settings.ini",
          "sha256": "$ini_hash",
          "kind": "ini",
          "origin": "settings"
        },
        {
          "path": "settings.json",
          "source": "$TMPDIR/source/settings.json",
          "target": "$TMPDIR/live/settings.json",
          "sha256": "$json_hash",
          "kind": "raw",
          "origin": "json"
        }
      ]
    }
    EOF

    tool="$TESTED/home-path/bin/hermesix"
    compat_tool="$TESTED/home-path/bin/hm-managed-config"

    set +e
    "$tool" diff --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live" > "$TMPDIR/diff.txt"
    diff_status=$?
    set -e
    test "$diff_status" -eq 1
    assertFileContains "$TMPDIR/diff.txt" 'missing settings.ini'
    assertFileContains "$TMPDIR/diff.txt" 'missing settings.json'

    "$tool" sync --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live" --apply
    "$tool" diff --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live" > "$TMPDIR/diff-clean.txt"
    assertFileContains "$TMPDIR/diff-clean.txt" 'no changes'
    "$compat_tool" diff --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live" > "$TMPDIR/diff-compat.txt"
    assertFileContains "$TMPDIR/diff-compat.txt" 'no changes'

    "$tool" redact "$TMPDIR/source/settings.json" --format json > "$TMPDIR/redacted.json"
    assertFileContains "$TMPDIR/redacted.json" '"name": "demo"'
    assertFileNotRegex "$TMPDIR/redacted.json" 'secret_token|drop-me|/home/demo/file'

    set +e
    "$tool" validate --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live" > "$TMPDIR/validate.txt" 2> "$TMPDIR/validate.err"
    validate_status=$?
    set -e
    test "$validate_status" -eq 1
    assertFileContains "$TMPDIR/validate.err" 'contains non-portable or sensitive JSON fields'

    "$tool" validate --include-sensitive --include-local-paths --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live" > "$TMPDIR/validate-allowed.txt"
    assertFileContains "$TMPDIR/validate-allowed.txt" 'manifest ok'

    cat > "$TMPDIR/traversal-manifest.json" <<EOF
    {
      "version": 1,
      "module": "programs.demo",
      "files": [
        {
          "path": "../escape.ini",
          "source": "$TMPDIR/source/settings.ini",
          "target": "$TMPDIR/live/../escape.ini",
          "sha256": "$ini_hash",
          "kind": "ini",
          "origin": "escape"
        }
      ]
    }
    EOF

    set +e
    "$tool" diff --manifest "$TMPDIR/traversal-manifest.json" --config-dir "$TMPDIR/live" > "$TMPDIR/traversal-diff.txt" 2> "$TMPDIR/traversal-diff.err"
    traversal_diff_status=$?
    "$tool" sync --manifest "$TMPDIR/traversal-manifest.json" --config-dir "$TMPDIR/live" --apply > "$TMPDIR/traversal-sync.txt" 2> "$TMPDIR/traversal-sync.err"
    traversal_sync_status=$?
    set -e
    test "$traversal_diff_status" -eq 1
    test "$traversal_sync_status" -eq 1
    assertFileContains "$TMPDIR/traversal-diff.err" 'relative path escapes config root'
    assertFileContains "$TMPDIR/traversal-sync.err" 'relative path escapes config root'
    assertPathNotExists "$TMPDIR/escape.ini"

    cat > "$TMPDIR/hash-mismatch-manifest.json" <<EOF
    {
      "version": 1,
      "module": "programs.demo",
      "files": [
        {
          "path": "hash-mismatch.ini",
          "source": "$TMPDIR/source/settings.ini",
          "target": "$TMPDIR/live/hash-mismatch.ini",
          "sha256": "not-the-hash",
          "kind": "ini",
          "origin": "hash-mismatch"
        }
      ]
    }
    EOF

    set +e
    "$tool" sync --manifest "$TMPDIR/hash-mismatch-manifest.json" --config-dir "$TMPDIR/live" --apply > "$TMPDIR/hash-mismatch-sync.txt" 2> "$TMPDIR/hash-mismatch-sync.err"
    hash_mismatch_status=$?
    set -e
    test "$hash_mismatch_status" -eq 1
    assertFileContains "$TMPDIR/hash-mismatch-sync.err" 'source sha256 mismatch'
    assertPathNotExists "$TMPDIR/live/hash-mismatch.ini"
  '';
}
