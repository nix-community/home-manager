{ config, ... }:

{
  services.swayosd = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "swayosd";
      outPath = "@swayosd@";
    };
    display = "DISPLAY";
    stylePath = "/etc/xdg/swayosd/style.css";
    topMargin = 0.1;
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/swayosd.service \
      ${
        builtins.toFile "swayosd.service" ''
          [Install]
          WantedBy=graphical-session.target

          [Service]
          ExecStart=@swayosd@/bin/swayosd-server --display DISPLAY --style /etc/xdg/swayosd/style.css --top-margin 0.100000
          Restart=always
          RestartSec=2s
          Type=simple

          [Unit]
          After=graphical-session.target
          ConditionEnvironment=WAYLAND_DISPLAY
          Description=Volume/backlight OSD indicator
          Documentation=man:swayosd(1)
          PartOf=graphical-session.target
          StartLimitBurst=5
          StartLimitIntervalSec=10
        ''
      }
  '';
}
