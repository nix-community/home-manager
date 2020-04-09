{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    systemd.user.timers.test-timer = {
      Unit = { Description = "A basic test timer"; };

      Timer = { OnUnitActiveSec = "1h 30m"; };

      Install = { WantedBy = [ "timers.target" ]; };
    };

    nmt.script = ''
      unitDir=home-files/.config/systemd/user
      timerFile=$unitDir/test-timer.timer

      assertFileExists $timerFile
      assertFileContent $timerFile ${./timers-expected.conf}

      assertFileExists $unitDir/timers.target.wants/test-timer.timer
    '';
  };
}
