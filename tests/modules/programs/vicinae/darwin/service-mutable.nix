{ config, ... }:
{
  programs.vicinae = {
    enable = true;
    service.enable = true;
    mutableSettings = true;
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.21.0";
      outPath = "@vicinae@";
    };
    enableFirefoxIntegration = false;

    settings.font.normal.size = 12;
  };

  nmt.script = ''
    assertFileContent "home-files/.config/vicinae/home-manager.json" ${../read-only-layer.json}
    assertPathNotExists "home-files/.config/vicinae/settings.json"

    serviceFile=LaunchAgents/org.nix-community.home.vicinae.plist
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./agent-mutable.plist}
  '';
}
