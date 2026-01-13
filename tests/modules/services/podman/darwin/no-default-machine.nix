{
  services.podman = {
    enable = true;
    useDefaultMachine = false;
    machines = { };
  };

  nmt.script = ''
    serviceDir=LaunchAgents

    # Check that the default machine watchdog launchd service does not exists
    agentFile=$serviceDir/org.nix-community.home.podman-machine-podman-machine-default.plist
    assertPathNotExists $agentFile

    # Verify home activation script doesn't create default machine
    activationScript=activate
    assertFileExists $activationScript
    assertFileNotRegex $activationScript 'podman-machine-default'
  '';
}
