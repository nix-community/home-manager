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
        center = [ "Window Title" ];
        right = [
          "SystemInfo"
          "Clock"
        ];
      };
      workspaces = {
        visibility_mode = "MonitorSpecific";
        show_empty = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ashell/config.toml
    assertFileContent home-files/.config/ashell/config.toml ${./basic-toml-config-expected.toml}
  '';
}
