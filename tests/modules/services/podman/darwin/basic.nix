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
    assertFileRegex activate '[-][-]volume "$HOME/.config/containers:/var/home/core/.config/containers"'
    assertFileRegex activate '[-][-]volume "/Users:/Users"'
    assertFileRegex activate '[-][-]volume "/private:/private"'
    assertFileRegex activate '[-][-]volume "/var/folders:/var/folders"'

    # Verify that config directory is automatically mounted into the machine
    # at the canonical /var/home path (because /home is a symlink on the guest)
    assertFileRegex activate '\$HOME/\.config/containers:/var/home/core/\.config/containers'

    # Verify the install-based config materialization is wired in
    assertFileRegex activate 'podmanContainersConfig'
    assertFileRegex activate 'install -m 0644'
    assertFileRegex activate 'policy\.json'
    assertFileRegex activate 'registries\.conf'
    assertFileRegex activate 'storage\.conf'
    assertFileRegex activate 'containers\.conf'
  '';
}
