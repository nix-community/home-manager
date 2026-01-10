{ config, pkgs, ... }:
{
  services.proton-pass-agent = {
    enable = true;
    socket = "proton-pass-agent/socket";
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        plistFile=LaunchAgents/org.nix-community.home.proton-pass-agent.plist

        assertFileExists $plistFile
        assertFileContent $plistFile ${./basic-service-expected.plist}
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/proton-pass-agent.service

        assertFileExists $serviceFile
        assertFileContent $serviceFile  ${./basic-service-expected.service}
      '';
}
