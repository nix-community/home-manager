{ pkgs, ... }:
let
  ashellPackage = pkgs.runCommand "ashell-0.5.0" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/ashell
    chmod +x $out/bin/ashell
  '';
in
{
  programs.ashell = {
    enable = true;
    package = ashellPackage;
    settings = {
      modules = {
        left = [ "Workspaces" ];
        center = [ "WindowTitle" ];
        right = [ "SystemInfo" ];
      };
      workspaces = {
        visibilityMode = "MonitorSpecific";
        showEmpty = true;
      };
      systemInfo = {
        refreshRate = 1000;
        showCpu = true;
        showMemory = true;
      };
    };
  };

  test.asserts.warnings.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/ashell/config.toml
    assertFileContent home-files/.config/ashell/config.toml ${./camelcase-migration-expected.toml}
  '';
}
