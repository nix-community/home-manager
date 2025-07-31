{ config, pkgs, ... }:
{
  programs.nh = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "4.0.0"; };

    flake = "/path/to/flake";
    osFlake = "/path/to/osFlake";
    homeFlake = "/path/to/homeFlake";
    darwinFlake = "/path/to/darwinFlake";

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
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_OS_FLAKE="/path/to/osFlake"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_HOME_FLAKE="/path/to/homeFlake"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_DARWIN_FLAKE="/path/to/darwinFlake"'
  '';
}
