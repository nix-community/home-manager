{ pkgs, ... }:

let
  ashellPackage = pkgs.runCommand "ashell-0.4.1" { } ''
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
        center = [ "Window Title" ];
        right = [
          "SystemInfo"
          "Clock"
        ];
      };
      workspaces = {
        visibilityMode = "MonitorSpecific";
        showEmpty = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ashell.yml
    assertFileContent home-files/.config/ashell.yml ${./basic-yaml-config-expected.yml}
  '';
}
