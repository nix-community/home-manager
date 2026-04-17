{ lib, pkgs, ... }:

{
  services.glance.enable = true;

  nmt.script = lib.mkMerge [
    ''
      configFile=home-files/.config/glance/glance.yml
      assertFileContent $configFile ${./glance-default-config.yml}
    ''
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''
      serviceFile=home-files/.config/systemd/user/glance.service
      serviceFile=$(normalizeStorePaths $serviceFile)
      assertFileContent $serviceFile ${./glance.service}
    '')
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
      serviceFile=LaunchAgents/org.nix-community.home.glance.plist
      serviceFile=$(normalizeStorePaths $serviceFile)
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./glance.plist}
    '')
  ];
}
