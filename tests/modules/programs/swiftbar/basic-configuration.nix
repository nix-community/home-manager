{ config, pkgs, ... }:

let package = pkgs.swiftbar;
in {
  programs.swiftbar = {
    enable = true;
    inherit package;
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.swiftbar.plist

    assertFileExists $serviceFile
    assertFileContains $serviceFile ${package.outPath}
    assertFileExists home-path/Applications/SwiftBar.app/Contents/MacOS/SwiftBar
  '';
}
