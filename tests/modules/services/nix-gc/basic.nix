{
  nix.gc = {
    automatic = true;
    frequency = "monthly";
    randomizedDelaySec = "42min";
    options = "--delete-older-than 30d --max-freed $((64 * 1024**3))";
  };

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
