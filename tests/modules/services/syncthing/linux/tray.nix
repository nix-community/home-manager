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
      # See earlier iterations of #4276: the author wasn't able to rewrite the
      # nix store path to @syncthingtray@, therefore the test matches only
      # a substring.
      assertFileContains home-files/.config/systemd/user/syncthingtray.service "/bin/syncthingtray' '--wait'"
    '';
  };
}
