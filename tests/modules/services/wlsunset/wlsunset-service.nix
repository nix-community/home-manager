{ config, pkgs, ... }:

{
  config = {
    services.wlsunset = {
      enable = true;
      package = config.lib.test.mkStubPackage { outPath = "@wlsunset@"; };
      latitude = "12.3";
      longitude = "128.8";
      temperature.day = 6000;
      temperature.night = 3500;
      gamma = "0.6";
      systemdTarget = "test.target";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/wlsunset.service

      assertFileExists $serviceFile
      assertFileContent $serviceFile ${./wlsunset-service-expected.service}
    '';
  };
}
