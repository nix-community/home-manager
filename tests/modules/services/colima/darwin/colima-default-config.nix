{ lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: rec {
      colima = super.writeShellScriptBin "colima" "" // {
        outPath = "@colima@";
      };
      perl = super.writeShellScriptBin "perl" "" // {
        outPath = "@perl@";
      };
      docker = super.writeShellScriptBin "docker" "" // {
        outPath = "@docker@";
      };
    })
  ];

  services.colima.enable = true;

  nmt.script = ''
    assertFileExists home-files/.colima/default/colima.yaml

    assertFileContent \
      home-files/.colima/default/colima.yaml \
      ${./expected.yaml}

    serviceFile=LaunchAgents/org.nix-community.home.colima.plist

    assertFileExists "$serviceFile"

    assertFileContent "$serviceFile" ${./expected-agent.plist}
  '';
}
