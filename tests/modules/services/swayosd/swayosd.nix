{ config, ... }:

{
  services.swayosd = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "swayosd";
      outPath = "@swayosd@";
    };
    maxVolume = 10;
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/swayosd.service \
      ${
        builtins.toFile "swayosd.service" ''
          [Install]
          WantedBy=graphical-session.target

          [Service]
          ExecStart=@swayosd@/bin/swayosd --max-volume 10
          Restart=always
          Type=simple

          [Unit]
          After=graphical-session.target
          ConditionEnvironment=WAYLAND_DISPLAY
          Description=Volume/backlight OSD indicator
          Documentation=man:swayosd(1)
          PartOf=graphical-session.target
        ''
      }
  '';
}
