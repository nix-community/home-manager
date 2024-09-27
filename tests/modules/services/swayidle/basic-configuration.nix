{ config, pkgs, lib, ... }:

{
  services.swayidle = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@swayidle@"; };
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

    assertFileExists "$serviceFile"

    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileContent "$serviceFileNormalized" ${
      builtins.toFile "expected.service" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        Environment=PATH=/nix/store/00000000000000000000000000000000-bash/bin
        ExecStart=@swayidle@/bin/dummy -w timeout 50 'notify-send -t 10000 -- "Screen lock in 10 seconds"' timeout 60 'swaylock -fF' timeout 300 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock -fF' lock 'swaylock -fF'
        Restart=always
        Type=simple

        [Unit]
        ConditionEnvironment=WAYLAND_DISPLAY
        Description=Idle manager for Wayland
        Documentation=man:swayidle(1)
        PartOf=graphical-session.target
      ''
    }
  '';
}
