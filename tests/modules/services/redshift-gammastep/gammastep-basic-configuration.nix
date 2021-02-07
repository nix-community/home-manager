{ config, pkgs, ... }:

{
  config = {
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = "0.0";
      longitude = "0.0";
    };

    nixpkgs.overlays = [
      (self: super: {
        gammastep = pkgs.writeScriptBin "dummy-gammastep" "" // {
          outPath = "@gammastep@";
        };
      })
    ];

    nmt.script = ''
      assertFileContent \
          home-files/.config/systemd/user/gammastep.service \
          ${./gammastep-basic-configuration-expected.service}
    '';
  };
}
