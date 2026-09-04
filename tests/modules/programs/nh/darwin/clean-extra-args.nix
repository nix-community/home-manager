{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 3d";
    };
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.nh-clean.plist"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileExists $serviceFile
    assertFileContent $serviceFileNormalized ${./clean-extra-args.plist}
  '';
}
