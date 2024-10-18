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
    assertFileContent \
      home-files/.config/systemd/user/swaync.service \
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
          Description=Swaync notification daemon
          Documentation=https://github.com/ErikReider/SwayNotificationCenter
        ''
      }
  '';
}
