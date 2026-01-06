args:

{
  config = {
    services.lorri.enable = true;

    nmt.script = ''
      serviceFile="LaunchAgents/org.nix-community.home.lorri.plist"
      serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
      assertFileExists "$serviceFile"
  '';
  };
}
