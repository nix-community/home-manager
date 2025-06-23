{
  services.home-manager.autoExpire = {
    enable = true;
    frequency = "weekly";
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.home-manager-auto-expire.plist
    assertFileExists "$serviceFile"

    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileContent "$serviceFileNormalized" ${./expected-agent.plist}
  '';
}
