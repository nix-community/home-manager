{ config, ... }:
{
  config = {
    services.devilspie2 = {
      enable = true;
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/devilspie2.service

      assertFileExists $serviceFile

      assertFileRegex $serviceFile 'ExecStart=.*/bin/devilspie2'
    '';
  };
}
