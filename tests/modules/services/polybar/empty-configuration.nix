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
      assertFileNotRegex $serviceFile 'X-Restart-Triggers=/nix/store/.*-polybar.conf$'
      assertFileRegex $serviceFile 'ExecStart=.*/bin/polybar-start'

      assertPathNotExists home-files/.config/polybar/config.ini
    '';
  };
}
