{ config, pkgs, lib, ... }:

{
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

  nmt.script = let
    escapeForRegex = builtins.replaceStrings [ "'" "*" ] [ "'\\''" "\\*" ];
    expectedArgs = escapeForRegex (lib.concatStringsSep " " [
      "-w"
      "timeout 50 'notify-send -t 10000 -- \"Screen lock in 10 seconds\"'"
      "timeout 60 'swaylock -fF'"
      "timeout 300 'swaymsg \"output * dpms off\"' resume 'swaymsg \"output * dpms on\"'"
      "before-sleep 'swaylock -fF'"
      "lock 'swaylock -fF'"
    ]);
  in ''
    serviceFile=home-files/.config/systemd/user/swayidle.service

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/swayidle ${expectedArgs}'
    assertFileRegex $serviceFile 'Restart=always'
    assertFileRegex $serviceFile 'Environment=.*PATH=${
      lib.makeBinPath [ pkgs.bash ]
    }'
  '';
}
