{ config, pkgs, ... }:

{
  config = {
    services.xsettingsd = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      settings = {
        "Net/ThemeName" = "Numix";
        "Xft/Antialias" = true;
        "Xft/Hinting" = true;
        "Xft/RGBA" = "rgb";
      };
    };
    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/xsettingsd.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*/bin/xsettingsd.*'

      assertFileExists ${config.services.xsettingsd.configFile}
      assertFileContent ${config.services.xsettingsd.configFile} \
        ${./basic-configuration.conf}
    '';
  };
}
