{
  nix.gc = {
    automatic = true;
    frequency = "monthly";
    options = "--delete-older-than 30d";
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.nix-gc.plist

    assertFileExists "$serviceFile"

    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
