{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.aria2 = {
      enable = true;

      settings = {
        listen-port = 60000;
        dht-listen-port = 60000;
        seed-ratio = 1.0;
        max-upload-limit = "50K";
        ftp-pasv = true;
      };

      extraConfig = ''
        # Extra aria2 configuration.
      '';
    };

    nixpkgs.overlays =
      [ (self: super: { aria2 = pkgs.writeScriptBin "dummy-aria2" ""; }) ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/aria2/aria2.conf \
        ${
          pkgs.writeText "aria2-expected-config.conf" ''
            dht-listen-port=60000
            ftp-pasv=true
            listen-port=60000
            max-upload-limit=50K
            seed-ratio=1.000000
            # Extra aria2 configuration.
          ''
        }
    '';
  };
}
