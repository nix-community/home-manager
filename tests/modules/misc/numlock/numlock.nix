{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xsession.numlock.enable = true;

    nixpkgs.overlays = [
      (self: super: { numlockx = pkgs.writeScriptBin "dummy-numlockx" ""; })
    ];

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/numlockx.service
      assertFileExists $serviceFile
    '';
  };
}
