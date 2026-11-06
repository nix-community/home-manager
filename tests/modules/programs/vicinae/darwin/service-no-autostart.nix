{ config, ... }:
{
  programs.vicinae = {
    enable = true;
    service = {
      enable = true;
      autoStart = false;
    };
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.21.0";
      outPath = "@vicinae@";
    };
    enableFirefoxIntegration = false;
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.vicinae.plist
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./agent-no-autostart.plist}
  '';
}
