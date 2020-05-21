{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xsession = {
      enable = true;
      windowManager.command = "window manager command";
      importedVariables = [ "EXTRA_IMPORTED_VARIABLE" ];
      initExtra = "init extra commands";
      profileExtra = "profile extra commands";
    };

    nixpkgs.overlays = [
      (self: super: {
        xorg = super.xorg // {
          setxkbmap = super.xorg.setxkbmap // { outPath = "@setxkbmap@"; };
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.xprofile
      assertFileContent \
        home-files/.xprofile \
        ${./basic-xprofile-expected.txt}

      assertFileExists home-files/.xsession
      assertFileContent \
        home-files/.xsession \
        ${./basic-xsession-expected.txt}

      assertFileExists home-files/.config/systemd/user/setxkbmap.service
      assertFileContent \
        home-files/.config/systemd/user/setxkbmap.service \
        ${./basic-setxkbmap-expected.service}
    '';
  };
}
