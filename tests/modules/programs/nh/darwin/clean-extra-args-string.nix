{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since=1 day";
    };
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.nh-clean.plist"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileExists $serviceFile
    assertFileContent $serviceFileNormalized ${./clean-extra-args-string.plist}
  '';
}
