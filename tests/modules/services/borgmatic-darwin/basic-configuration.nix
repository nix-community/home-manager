{
  services.borgmatic = {
    enable = true;
    frequency = "weekly";
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.borgmatic.plist

    assertFileExists "$serviceFile"

    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
