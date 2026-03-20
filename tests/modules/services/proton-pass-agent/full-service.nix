{ config, pkgs, ... }:
{
  services.proton-pass-agent = {
    enable = true;
    socket = "proton-pass-agent/socket";
    extraArgs = [
      "--share-id"
      "123456789"
      "--vault-name"
      "MySshKeyVault"
      "--refresh-interval"
      "7200"
      "--create-new-identities"
      "MySshKeyVault"
    ];
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        plistFile=LaunchAgents/org.nix-community.home.proton-pass-agent.plist

        assertFileExists $plistFile
        assertFileContent $plistFile ${./full-service-expected.plist}
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/proton-pass-agent.service

        assertFileExists $serviceFile
        assertFileContent $serviceFile  ${./full-service-expected.service}
      '';
}
