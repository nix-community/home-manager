{
  services.podman = {
    enable = true;
    useDefaultMachine = false;
    machines = {
      "dev-machine" = {
        cpus = 8;
        memory = 8192;
        diskSize = 200;
        rootful = true;
        autoStart = true;
        watchdogInterval = 60;
      };
      "test-machine" = {
        cpus = 2;
        memory = 4096;
        diskSize = 50;
        autoStart = false;
        watchdogInterval = 30;
      };
    };
  };

  nmt.script = ''
    serviceDir=LaunchAgents

    # Check that dev-machine watchdog exists (has autoStart = true)
    devAgentFile=$serviceDir/org.nix-community.home.podman-machine-dev-machine.plist
    assertFileExists $devAgentFile

    # Normalize and verify dev-machine agent file content
    devAgentFileNormalized=$(normalizeStorePaths "$devAgentFile")
    assertFileContent "$devAgentFileNormalized" ${./custom-machines-dev-expected-agent.plist}

    # Check that test-machine watchdog does NOT exist (has autoStart = false)
    testAgentFile=$serviceDir/org.nix-community.home.podman-machine-test-machine.plist
    assertPathNotExists $testAgentFile

    # Verify home activation creates both machines
    assertFileExists activate

    # Check dev-machine initialization with custom parameters
    assertFileRegex activate 'dev-machine'
    assertFileRegex activate 'podman machine init dev-machine'
    assertFileRegex activate '[-][-]cpus 8'
    assertFileRegex activate '[-][-]memory 8192'
    assertFileRegex activate '[-][-]disk-size 200'
    assertFileRegex activate '[-][-]rootful'

    # Check test-machine initialization
    assertFileRegex activate 'test-machine'
    assertFileRegex activate 'podman machine init test-machine'
    assertFileRegex activate '[-][-]cpus 2'
    assertFileRegex activate '[-][-]memory 4096'
    assertFileRegex activate '[-][-]disk-size 50'

    # Verify default machine is NOT created
    assertFileNotRegex activate 'podman-machine-default'

    # Verify that config directory is automatically mounted into all machines
    assertFileRegex activate '\$HOME/\.config/containers:/home/core/\.config/containers'
  '';
}
