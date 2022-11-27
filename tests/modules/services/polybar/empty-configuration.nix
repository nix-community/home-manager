{ config, pkgs, ... }:

{
  config = {
    services.polybar = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      script = "polybar bar &";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/polybar.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'X-Restart-Triggers=.*/.config/polybar/config.ini'
      assertFileRegex $serviceFile 'ExecStart=.*/bin/polybar-start'

      assertPathNotExists home-files/.config/polybar/config.ini
    '';
  };
}
