{ config, pkgs, lib, ... }:

{
  config = {
    services.swayidle = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      timeouts = [
        {
          timeout = 50;
          command = ''notify-send -t 10000 -- "Screen lock in 10 seconds"'';
        }
        {
          timeout = 60;
          command = "swaylock -fF";
        }
        {
          timeout = 300;
          command = ''swaymsg "output * dpms off"'';
          resumeCommand = ''swaymsg "output * dpms on"'';
        }
      ];
      events = [
        {
          event = "before-sleep";
          command = "swaylock -fF";
        }
        {
          event = "lock";
          command = "swaylock -fF";
        }
      ];
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/swayidle.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*-swayidle'
    '';
  };
}
