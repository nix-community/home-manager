{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    services.syncthing.tray = {
      enable = true;
      extraOptions = [ "--wait" ];
    };

    test.stubs.syncthingtray = { };

    nixpkgs.overlays = [
      (self: super: {
        syncthingtray-minimal =
          pkgs.runCommandLocal "syncthingtray" { pname = "syncthingtray"; }
          "mkdir $out";
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/syncthingtray.service
      assertFileContains home-files/.config/systemd/user/syncthingtray.service "ExecStart='@syncthingtray@/bin/syncthingtray' '--wait'"
    '';
  };
}
