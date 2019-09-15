{ config, ... }:
{
  config = {
    services.sxhkd.enable = true;

    nmt.script = ''
      local serviceFile=home-files/.config/systemd/user/sxhkd.service

      assertFileExists $serviceFile

      assertFileRegex $serviceFile 'ExecStart=.*/bin/sxhkd'

      assertFileRegex $serviceFile \
        'Environment=PATH=.*nix-profile/bin:/run/wrappers/bin:/run/current-system/sw/bin'
    '';
  };
}
