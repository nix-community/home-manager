{ lib, options, ... }:

{
  nix.gc = {
    automatic = true;
    frequency = "monthly";
    randomizedDelaySec = "42min";
    options = "--delete-older-than 30d --max-freed $((64 * 1024**3))";
  };

  test.asserts.warnings.expected = [
    "The option `nix.gc.frequency' defined in ${lib.showFiles options.nix.gc.frequency.files} has been changed to `nix.gc.dates' that has a different type. Please read `nix.gc.dates' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/nix-gc.service

    assertFileExists $serviceFile

    serviceFile=$(normalizeStorePaths $serviceFile)

    assertFileContent $serviceFile ${./expected.service}

    timerFile=home-files/.config/systemd/user/nix-gc.timer

    assertFileExists $timerFile

    timerFile=$(normalizeStorePaths $timerFile)

    assertFileContent $timerFile ${./expected.timer}

    nixgcScriptFile=$(grep -o \
      '/nix/store/.*-nix-gc' \
      $TESTED/home-files/.config/systemd/user/nix-gc.service
    )

    assertFileExists $nixgcScriptFile

    nixgcScriptFile=$(normalizeStorePaths $nixgcScriptFile)

    assertFileContent $nixgcScriptFile ${./nix-gc-script-expected}
  '';
}
