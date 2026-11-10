{ lib, ... }:

{
  home.file.foo = {
    text = "foo";
    onChange = "echo foo changed";
  };

  home.activation = {
    # Selected by name, and placed where alphabetical order would not put it.
    placeTheme = lib.hm.dag.entryBetween [ "onFilesChange" ] [ "linkGeneration" ] "echo placing theme";
    # Selected because it must run before linkGeneration.
    prepareTarget =
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
        "echo preparing target";
    otherWork = lib.hm.dag.entryAfter [ "writeBoundary" ] "echo other work";
  };

  home.activationFilesOnly = [
    "placeTheme"
    "noSuchBlock"
  ];

  nmt.script = ''
    assertFileContains activate 'hmFilesOnly=1'
    assertFileContains activate 'unset hmFilesOnly'
    assertFileContains activate 'if [[ ! -v hmFilesOnly ]]; then'
    assertFileRegex activate '^ *source .*-activation-files-only$'

    filesOnly=$(grep -m1 -o '[^ ]*-activation-files-only' "$TESTED/activate")

    # The files-only run holds exactly the selected blocks, in the order of
    # the full activation, which is not the alphabetical one.
    blocks() {
      grep -o '_iNote "Activating %s" "[^"]*"' "$1" | cut -d '"' -f 4
    }
    expected=$(blocks "$TESTED/activate" \
      | grep -xE 'checkFilesChanged|checkLinkTargets|prepareTarget|linkGeneration|placeTheme|onFilesChange')
    actual=$(blocks "$filesOnly")
    if [[ $actual != "$expected" ]]; then
      fail "Expected the files-only blocks to be '$expected' but got '$actual'."
    fi
    if [[ $expected == "$(sort <<< "$expected")" ]]; then
      fail "Expected the block order to differ from the alphabetical one."
    fi

    assertFileContains "$filesOnly" 'echo placing theme'
    assertFileContains "$filesOnly" 'echo preparing target'
    assertFileContains "$filesOnly" 'echo foo changed'
    assertFileNotRegex "$filesOnly" 'echo other work'
    assertFileNotRegex "$filesOnly" 'nix-env\|nix-store\|nix profile'

    # The run's status is not that of the last block's last command.
    if [[ $(tail -n 1 "$filesOnly") != ":" ]]; then
      fail "Expected the files-only blocks to end with a no-op."
    fi
  '';
}
