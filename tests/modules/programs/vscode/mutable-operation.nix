{
  config,
  lib,
  realPkgs,
  ...
}:
let
  operation = realPkgs.writeText "vscode-mutable-operation" ''
    ${config.lib.bash.initHomeManagerLib}
    ${import ../../../../modules/programs/vscode/mutableSettings.nix {
      inherit lib;
      pkgs = realPkgs;
      name = "Visual Studio Code";
    }}
  '';
  stat = lib.getExe' realPkgs.coreutils "stat";
in
{
  nmt.script = ''
    source ${operation}
    saved="$PWD/settings.json"
    cat ${./mutable-settings-live.json5} > "$saved"
    chmod 0640 "$saved"
    DRY_RUN=1 vscodeMutableSettings "$saved" ${./mutable-default-expected.json} || fail "Dry run failed"
    assertFileContent "$saved" ${./mutable-settings-live.json5}
    vscodeMutableSettings "$saved" ${./mutable-default-expected.json} || fail "Merge failed"
    assertFileContent "$saved" ${./expectedDefault.json}
    test "$(${stat} -c %a "$saved")" = 640 || fail "Existing permissions changed"
    vscodeMutableSettings "$saved" ${./mutable-default-expected.json} || fail "Repeated merge failed"
    assertFileContent "$saved" ${./expectedDefault.json}

    vscodeMutableSettings "$PWD/new.json" ${./expectedMissing.json} || fail "Creation failed"
    assertFileContent "$PWD/new.json" ${./expectedMissing.json}
    test "$(${stat} -c %a "$PWD/new.json")" = 600 || fail "New settings must be private"
    printf ' \n\t\n' > "$saved"
    vscodeMutableSettings "$saved" ${./expectedMissing.json} || fail "Blank settings failed"
    assertFileContent "$saved" ${./expectedMissing.json}

    cat ${./mutable-settings-malformed.json5} > "$saved"
    if vscodeMutableSettings "$saved" ${./expectedMissing.json} > "$PWD/malformed-saved.log" 2>&1; then
      fail "Malformed saved settings accepted"
    fi
    assertFileContent "$saved" ${./mutable-settings-malformed.json5}
    assertFileContains "$PWD/malformed-saved.log" "Cannot parse Visual Studio Code settings at '$saved' as JSON5"
    cat ${./mutable-settings-live.json5} > "$saved"
    if vscodeMutableSettings "$saved" ${./mutable-settings-malformed.json5} > "$PWD/malformed-declared.log" 2>&1; then
      fail "Malformed declared settings accepted"
    fi
    assertFileContent "$saved" ${./mutable-settings-live.json5}

    assertFileContains "$PWD/malformed-declared.log" "Cannot parse the declared Visual Studio Code settings"

    ln -s settings.json "$PWD/link.json"
    vscodeMutableSettings "$PWD/link.json" ${./mutable-default-expected.json} || fail "Linked settings failed"
    assertLinkPointsTo "$PWD/link.json" settings.json
    assertFileContent "$saved" ${./expectedDefault.json}
    ln -s absent.json "$PWD/dangling.json"
    if vscodeMutableSettings "$PWD/dangling.json" ${./expectedMissing.json} > "$PWD/dangling.log" 2>&1; then
      fail "Dangling link accepted"
    fi
    assertFileContains "$PWD/dangling.log" "Cannot resolve Visual Studio Code settings"
    assertLinkPointsTo "$PWD/dangling.json" absent.json
    assertPathNotExists "$PWD/absent.json"

    if (
      chmod() {
        command cat ${./concurrent.json} > "$saved"
        command chmod "$@"
      }
      vscodeMutableSettings "$saved" ${./mutable-default-expected.json}
    ); then
      fail "Concurrent saved settings overwritten"
    fi
    assertFileContent "$saved" ${./concurrent.json}
    if (
      printf() {
        builtin printf "$@"
        command cat ${./concurrent.json} > "$PWD/appearing.json"
      }
      vscodeMutableSettings "$PWD/appearing.json" ${./expectedMissing.json}
    ); then
      fail "Newly appearing settings overwritten"
    fi
    assertFileContent "$PWD/appearing.json" ${./concurrent.json}
    test -z "$(find "$PWD" -maxdepth 1 \( -name '*.snapshot.*' -o -name '*.candidate.*' \) -print -quit)" \
      || fail "Operation left temporary files"
  '';
}
