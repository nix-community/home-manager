{ config, pkgs, ... }:

{
  config = {
    services.redshift = {
      enable = true;
      provider = "manual";
      latitude = "0.0";
      longitude = "0.0";
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
          home-files/.config/systemd/user/redshift.service \
          ${./redshift-basic-configuration-expected.service}
    '';
  };
}
