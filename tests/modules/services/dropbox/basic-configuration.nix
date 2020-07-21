{ config, pkgs, ... }:

{
  config = {
    services.dropbox = {
      enable = true;
      path = "${config.home.homeDirectory}/dropbox";
    };

    nixpkgs.overlays = [
      (self: super: {
        dropbox-cli = pkgs.writeScriptBin "dummy-dropbox-cli" "" // {
          outPath = "@dropbox-cli@";
        };
      })
    ];

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/dropbox.service

      assertFileExists $serviceFile
    '';

  };
}
