{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.podman = {
    enable = true;
    darwin.useDefaultMachine = true;
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
    assertFileRegex activate '[-][-]cpus 4'
    assertFileRegex activate '[-][-]memory 2048'
    assertFileRegex activate '[-][-]disk-size 100'
  '';
}
