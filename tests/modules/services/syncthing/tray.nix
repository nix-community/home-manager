{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.syncthing.tray.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        syncthingtray-minimal =
          pkgs.runCommandLocal "syncthingtray" { pname = "syncthingtray"; }
          "mkdir $out";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/syncthingtray.service
    '';
  };
}
