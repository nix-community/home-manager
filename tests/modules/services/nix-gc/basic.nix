{ ... }:

{
  nix.gc = {
    automatic = true;
    frequency = "monthly";
    options = "--delete-older-than 30d";
  };

  test.stubs.nix = { name = "nix"; };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/nix-gc.service

    assertFileExists $serviceFile

    serviceFile=$(normalizeStorePaths $serviceFile)

    assertFileContent $serviceFile ${./expected.service}

    timerFile=home-files/.config/systemd/user/nix-gc.timer

    assertFileExists $timerFile

    timerFile=$(normalizeStorePaths $timerFile)

    assertFileContent $timerFile ${./expected.timer}
  '';
}
