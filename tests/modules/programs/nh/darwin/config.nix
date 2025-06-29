{
  programs.nh = {
    enable = true;

    flake = "/path/to/flake";

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
  '';
}
