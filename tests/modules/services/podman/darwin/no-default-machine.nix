{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.podman = {
    enable = true;
    darwin = {
      useDefaultMachine = false;
      machines = { };
    };
  };

  nmt.script = ''
    serviceDir=LaunchAgents

    # Verify no launchd agents are created
    agentCount=$(find $serviceDir -name "org.nix-community.home.podman-machine-*.plist" 2>/dev/null | wc -l)
    if [[ $agentCount -ne 0 ]]; then
      echo "Expected no podman machine launchd agents, but found $agentCount"
      exit 1
    fi

    # Verify home activation script doesn't create default machine
    activationScript=activate
    assertFileExists $activationScript
    assertFileNotRegex $activationScript 'podman-machine-default'
  '';
}
