{ config, pkgs, ... }: {
  config = {
    services.pbgopy.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        pbgopy = pkgs.writeScriptBin "dummy-pbgopy" "" // {
          outPath = "@pbgopy@";
        };
      })
    ];

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/pbgopy.service

      assertFileExists $serviceFile

      assertFileContains $serviceFile \
        'ExecStart=@pbgopy@/bin/pbgopy serve --ttl 24h'
    '';
  };
}
