{ ... }:

{
  services.avizo = {
    enable = true;
    settings = {
      default = {
        time = 1.0;
        y-offset = 0.5;
        fade-in = 0.1;
        fade-out = 0.2;
        padding = 10;
      };
    };
  };

  test.stubs.avizo = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/avizo.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${
      builtins.toFile "expected" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        ExecStart=@avizo@/bin/avizo-service
        Restart=always
        Type=simple

        [Unit]
        After=graphical-session.target
        ConditionEnvironment=WAYLAND_DISPLAY
        Description=Volume/backlight OSD indicator
        Documentation=man:avizo(1)
        PartOf=graphical-session.target
      ''
    }

    configFile=home-files/.config/avizo/config.ini
    assertFileExists $configFile
    assertFileContent $configFile ${
      builtins.toFile "expected" ''
        [default]
        fade-in=0.100000
        fade-out=0.200000
        padding=10
        time=1.000000
        y-offset=0.500000
      ''
    }
  '';
}
