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

    assertFileExists home-files/.config/systemd/user/colima.service

    assertFileContent \
      home-files/.config/systemd/user/colima.service \
      ${./expected-service.service}
  '';
}
