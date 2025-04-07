{ config, ... }:

{
  services.swaync = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "swaync";
      outPath = "@swaync@";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/swaync.service
    serviceFile=$(normalizeStorePaths $serviceFile)

    assertFileContent \
      $serviceFile \
      ${
        builtins.toFile "swaync.service" ''
          [Install]
          WantedBy=graphical-session.target

          [Service]
          BusName=org.freedesktop.Notifications
          ExecStart=@swaync@/bin/swaync
          Restart=on-failure
          Type=dbus

          [Unit]
          After=graphical-session.target
          ConditionEnvironment=WAYLAND_DISPLAY
          Description=Swaync notification daemon
          Documentation=https://github.com/ErikReider/SwayNotificationCenter
          PartOf=graphical-session.target
          X-Restart-Triggers=/nix/store/00000000000000000000000000000000-config.json
        ''
      }
  '';
}
