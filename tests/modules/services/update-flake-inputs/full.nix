{ pkgs, ... }:
{
  services.update-flake-inputs = {
    enable = true;
    directories = [
      "/some path"
      "/other path"
    ];
    onCalendar = "04:00";
    randomizedDelaySec = "45 minutes";
    fixedRandomDelay = true;
    persistent = false;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/update-flake-inputs.service
    normalizedServiceFile=$(normalizeStorePaths "$serviceFile")
    assertFileContent $normalizedServiceFile ${./expected-full.service}

    assertFileContent home-files/.config/systemd/user/update-flake-inputs.timer ${./expected-full.timer}
  '';
}
