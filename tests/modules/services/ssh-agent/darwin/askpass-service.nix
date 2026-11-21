{ config, ... }:

{
  services.ssh-agent = {
    enable = true;
    askpass = "/dev/null";
    package = config.lib.test.mkStubPackage { outPath = "@openssh@"; };
  };

  nmt.script = ''
    assertFileContent \
      LaunchAgents/org.nix-community.home.ssh-agent.plist \
      ${./askpass-service-expected.plist}
  '';
}
