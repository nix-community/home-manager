{ lib, pkgs, ... }:
{
  services.glance = {
    enable = true;
    settings = {
      server.port = 5678;
      pages = [
        {
          name = "Home";
          columns = [
            {
              size = "full";
              widgets = [
                { type = "calendar"; }
                {
                  type = "weather";
                  location = "London, United Kingdom";
                }
              ];
            }
          ];
        }
      ];
    };
  };

  nmt.script = lib.mkMerge [
    ''
      configFile=home-files/.config/glance/glance.yml
      assertFileContent $configFile ${./glance-example-config.yml}
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
