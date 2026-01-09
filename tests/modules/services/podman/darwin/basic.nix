{
  services.podman = {
    enable = true;
    useDefaultMachine = true;
  };

  nmt.script = ''
    serviceDir=LaunchAgents

    # Check that the default machine watchdog launchd service exists
    agentFile=$serviceDir/org.nix-community.home.podman-machine-podman-machine-default.plist
    assertFileExists $agentFile

    # Normalize and verify agent file content
    agentFileNormalized=$(normalizeStorePaths "$agentFile")
    assertFileContent "$agentFileNormalized" ${./basic-expected-agent.plist}

    # Verify home activation creates the default machine
    assertFileExists activate
    assertFileRegex activate 'podman-machine-default'
    assertFileRegex activate 'podman machine init podman-machine-default'
    assertFileNotRegex activate '[-][-]cpus'
    assertFileNotRegex activate '[-][-]disk-size'
    assertFileNotRegex activate '[-][-]image'
    assertFileNotRegex activate '[-][-]memory'
    assertFileNotRegex activate '[-][-]rootful'
    assertFileNotRegex activate '[-][-]swap'
    assertFileNotRegex activate '[-][-]timezone'
    assertFileNotRegex activate '[-][-]username'
    assertFileNotRegex activate '[-][-]volumes'

    # Verify that config directory is automatically mounted into the machine
    assertFileRegex activate '\$HOME/\.config/containers:/home/core/\.config/containers'
  '';
}
