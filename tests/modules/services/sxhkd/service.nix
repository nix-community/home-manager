{ config, ... }:
{
  config = {
    services.sxhkd = {
      enable = true;
      extraPath = "/home/the-user/bin:/extra/path/bin";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/sxhkd.service

      assertFileExists $serviceFile

      assertFileRegex $serviceFile 'ExecStart=.*/bin/sxhkd'

      assertFileRegex $serviceFile \
        'Environment=PATH=.*\.nix-profile/bin:/home/the-user/bin:/extra/path/bin'
    '';
  };
}
