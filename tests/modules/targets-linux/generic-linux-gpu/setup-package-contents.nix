{ config, lib, ... }:

{
  targets.genericLinux.gpu = {
    enable = true;
    nixStateDirectory = "/custom/state/directory";
  };

  nmt.script = ''
    setupScript="$TESTED/home-path/bin/non-nixos-gpu-setup"
    assertFileExists "$setupScript"
    assertFileIsExecutable "$setupScript"

    # Check that gcroots dir was set
    cat "$setupScript"
    assertFileRegex "$setupScript" ' "/custom/state/directory"/gcroots'

    # Check that no placeholders remain
    assertFileNotRegex "$setupScript" '@@[^@]\+@@'

    # Check that expected files are present and free of placeholders
    storePath="$(dirname "$(readlink "''${setupScript}")")"/../
    expectedFiles=(
      lib/systemd/system/non-nixos-gpu.service
    )

    for f in "''${expectedFiles[@]}"; do
      assertFileExists "$storePath/$f"
      assertFileNotRegex "$storePath/$f" '@@[^@]\+@@'
    done
  '';
}
