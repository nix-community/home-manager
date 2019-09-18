{ config, ... }:
{
  config = {
    services.sxhkd = {
      enable = true;
    };

    nmt.script = ''
      local serviceFile=home-files/.config/systemd/user/sxhkd.service

      assertFileExists $serviceFile

      assertFileRegex $serviceFile 'ExecStart=.*/bin/sxhkd'
    '';
  };
}
