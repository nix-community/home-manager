{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = [ ];
    };
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.nh-clean.plist"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileExists $serviceFile
    assertFileContent $serviceFileNormalized ${./launchd.plist}
  '';
}
