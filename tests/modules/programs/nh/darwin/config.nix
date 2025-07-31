{
  programs.nh = {
    enable = true;

    flake = "/path/to/flake";
    osFlake = "/path/to/osFlake";
    homeFlake = "/path/to/homeFlake";
    darwinFlake = "/path/to/darwinFlake";

    clean = {
      enable = true;
      dates = "weekly";
    };
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.nh-clean.plist"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileExists $serviceFile
    assertFileContent $serviceFileNormalized ${./launchd.plist}

    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_FLAKE="/path/to/flake"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_OS_FLAKE="/path/to/osFlake"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_HOME_FLAKE="/path/to/homeFlake"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh 'NH_DARWIN_FLAKE="/path/to/darwinFlake"'
  '';
}
