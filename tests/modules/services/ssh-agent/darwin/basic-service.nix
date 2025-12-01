{ config, ... }:

{
  services.ssh-agent = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@openssh@"; };
  };

  nmt.script = ''
    assertFileContent \
      LaunchAgents/org.nix-community.home.ssh-agent.plist \
      ${./basic-service-expected.plist}
  '';
}
