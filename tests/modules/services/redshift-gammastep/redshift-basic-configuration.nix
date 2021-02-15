{ config, pkgs, ... }:

{
  config = {
    services.redshift = {
      enable = true;
      brightness = {
        day = 1.00;
        night = 0.75;
      };
      provider = "manual";
      latitude = 0.0;
      longitude = "0.0";
      settings = {
        redshift = {
          adjustment-method = "randr";
          gamma = 0.8;
        };
        randr = { screen = 0; };
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        redshift = pkgs.writeScriptBin "dummy-redshift" "" // {
          outPath = "@redshift@";
        };
      })
    ];

    nmt.script = ''
      assertFileContent \
          home-files/.config/redshift/redshift.conf \
          ${./redshift-basic-configuration-file-expected.conf}
      assertFileContent \
          home-files/.config/systemd/user/redshift.service \
          ${./redshift-basic-configuration-expected.service}
    '';
  };
}
