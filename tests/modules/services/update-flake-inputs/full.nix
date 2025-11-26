{ pkgs, ... }:
{
  services.update-flake-inputs = {
    enable = true;
    directories = [
      "/some path"
      "/other path"
    ];
    afterUpdateCommands = [
      "command arg1 arg2"
      "other_command arg1"
    ];
    afterUpdateCommandsDependencies = [
      pkgs.coreutils
      pkgs.gitMinimal
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

    scriptFile="$(
      grep '^ExecStart=' "$TESTED/$serviceFile" |
      cut --delimiter== --fields=2 |
      cut --delimiter=' ' --fields=1
    )"
    normalizedScriptFile=$(normalizeStorePaths "$scriptFile")
    assertFileContent "$normalizedScriptFile" ${./expected-full.bash}
  '';
}
