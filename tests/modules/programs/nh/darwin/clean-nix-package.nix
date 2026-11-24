{ config, ... }:

{
  nix.package = config.lib.test.mkStubPackage { name = "my-test-nix"; };

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.nh-clean.plist"

    assertFileExists $serviceFile
    assertFileRegex $serviceFile '<string>/nix/store/[a-z0-9]*-my-test-nix/bin</string>'
  '';
}
