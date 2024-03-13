{ config, pkgs, ... }:

{
  config = {
    services.eww = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-eww" "";
    };

    nmt.script = ''
      local serviceFile=home-files/.config/systemd/user/eww.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*/bin/eww --no-daemonize'
      assertFileRegex $serviceFile 'ExecStop=.*/bin/eww kill'
      assertFileRegex $serviceFile 'ExecReload=.*/bin/eww reload'
    '';
  };
}
