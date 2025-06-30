{ config, pkgs, ... }:
{
  programs.nh = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "4.0.0"; };

    flake = "/path/to/flake";

    clean = {
      enable = true;
      dates = "daily";
    };
  };

  nmt.script = ''
    unitDir=home-files/.config/systemd/user
    timerFile=$unitDir/nh-clean.timer

    assertFileExists $timerFile
    assertFileContent $timerFile ${pkgs.writeText "timer-expected" ''
      [Install]
      WantedBy=timers.target

      [Timer]
      OnCalendar=daily
      Persistent=true

      [Unit]
      Description=Run nh clean
    ''}
    assertFileExists $unitDir/timers.target.wants/nh-clean.timer

    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_FLAKE="/path/to/flake"'
  '';
}
